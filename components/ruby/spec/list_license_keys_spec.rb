require "chef-licensing/list_license_keys"
require "chef-licensing/config"
require "spec_helper"
require "logger"

RSpec.describe ChefLicensing::ListLicenseKeys do

  let(:logger) { Logger.new(STDERR) }

  let(:output_stream) {
    StringIO.new
  }

  let(:license_keys) {
    ["tmns-bea68bbb-1e85-44ea-8b98-a654b011174b-4227"]
  }

  let(:opts_for_llk) {
    {
      output: output_stream,
      license_keys: license_keys,
    }
  }

  let(:describe_api_data) { JSON.parse(File.read("spec/fixtures/api_response_data/valid_describe_api_response.json")) }

  before do
    logger.level = Logger::INFO
    ChefLicensing.configure do |conf|
      conf.chef_product_name = "inspec"
      conf.chef_entitlement_id = "testing_entitlement_id"
      conf.license_server_url = "http://localhost-license-server/License"
      conf.license_server_url_check_in_file = true
      conf.logger = logger
      conf.output = output_stream
    end
  end

  before do
    stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/desc")
      .with(query: { licenseId: license_keys.join(","), entitlementId: ChefLicensing::Config.chef_entitlement_id })
      .to_return(body: { data: describe_api_data, status_code: 200 }.to_json,
                 headers: { content_type: "application/json" })
  end

  describe "when there are no license_keys on the system" do
    let(:opts_for_llk) {
      {
        output: output_stream,
        license_keys: [],
      }
    }

    it "exits with no information about licenses" do
      expect { described_class.new(opts_for_llk).display }.to raise_error(SystemExit)
      expect(output_stream.string).to include("No license keys found on disk.")
    end
  end

  describe "when there are license_keys on the system" do
    it "displays the information about the license keys without errors" do
      expect { described_class.new(opts_for_llk).display }.to_not raise_error
      expect(output_stream.string).to include("+------------ License Information ------------+")
      expect(output_stream.string).to include("License Key     :")
      expect(output_stream.string).to include("Type            :")
    end
  end

  describe "when the information is not fetched correctly from the server" do
    before do
      stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/desc")
        .with(query: { licenseId: license_keys.join(","), entitlementId: ChefLicensing::Config.chef_entitlement_id })
        .to_return(body: { status_code: 404 }.to_json,
                   headers: { content_type: "application/json" })
    end

    it "exits with error message about DescribeError" do
      expect { described_class.new(opts_for_llk).display }.to raise_error(SystemExit)
      expect(output_stream.string).to include("Error occured while fetching license information: ChefLicensing::DescribeError")
    end
  end

  describe "when the license key is not fetched correctly from the system" do
    let(:unsupported_version_license_dir) { "spec/fixtures/unsupported_version_license" }
    let(:opts_for_llk) {
      {
        output: output_stream,
        dir: unsupported_version_license_dir,
      }
    }

    before do
      stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/listLicenses")
        .to_return(body: { data: [], status_code: 404 }.to_json,
                  headers: { content_type: "application/json" })
      ChefLicensing::Context.current_context = nil
    end

    it "exits with error message about LicenseKeyNotFetchedError" do
      expect { described_class.new(opts_for_llk).display }.to raise_error(ChefLicensing::InvalidFileFormatVersion, /License File version 0.0.0 not supported./)
    end
  end

  describe "when there are license_keys on the system and overview of the license is fetched" do
    it "displays an overview information about the license keys without errors" do
      expect { described_class.new(opts_for_llk).display_overview }.to_not raise_error
      expect(output_stream.string).to include("License Details")
      expect(output_stream.string).to include("Validity         :")
      expect(output_stream.string).to include("No. Of Units     : 2 Nodes")
    end
  end

  describe "when the license keys are fetched from the local licensing server" do
    before do
      ChefLicensing.configure do |config|
        config.is_local_license_service = nil
        config.license_server_url = "http://localhost-license-server/License"
      end
      stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/listLicenses")
        .to_return(body: { data: ["tmns-bea68bbb-1e85-44ea-8b98-a654b011174b-4227"], status_code: 200 }.to_json,
        headers: { content_type: "application/json" })
      ChefLicensing::Context.current_context = nil
    end

    it "displays the information about the license keys without errors" do
      expect { described_class.new({ output: output_stream }).display }.to_not raise_error
      expect(output_stream.string).to include("+------------ License Information ------------+")
      expect(output_stream.string).to include("License Key     :")
      expect(output_stream.string).to include("Type            :")
    end
  end
end
