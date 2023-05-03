require "chef-licensing/list_license_keys"
require "chef-licensing/config"
require "spec_helper"
require "logger"

RSpec.describe ChefLicensing::ListLicenseKeys do

  let(:logger) { Logger.new(STDERR) }

  let(:output_stream) {
    StringIO.new
  }

  before do
    logger.level = Logger::INFO
    ChefLicensing.configure do |conf|
      conf.chef_product_name = "inspec"
      conf.chef_entitlement_id = "testing_entitlement_id"
      conf.license_server_url = "http://localhost-license-server/License"
      conf.license_server_api_key = "xDblv65Xt84wULmc8qTN78a3Dr2OuuKxa6GDvb67"
      conf.logger = logger
      conf.output = output_stream
    end
  end

  describe "when there are no license_keys on the system" do
    let(:license_keys) { [] }

    let(:opts_for_llk) {
      {
        output: output_stream,
        license_keys: license_keys,
      }
    }

    it "exits with no information about licenses" do
      expect { described_class.new(opts_for_llk).display }.to raise_error(SystemExit)
      expect(output_stream.string).to include("No license keys found on disk.")
    end
  end

  describe "when there are license_keys on the system" do
    let(:license_keys) {
      ["tmns-bea68bbb-1e85-44ea-8b98-a654b011174b-4227"]
    }

    let(:opts_for_llk) {
      {
        output: output_stream,
        license_keys: license_keys,
      }
    }

    let(:describe_api_data) {
      {
        "license" => [{
          "licenseKey" => "guid",
          "serialNumber" => "testing",
          "name" => "testing",
          "status" => "active",
          "start" => "2022-12-02",
          "end" => "2023-12-02",
          "licenseType" => "trial",
          "limits" => [
             {
              "testing" => "software",
               "id" => "guid",
               "amount" => 2,
               "measure" => "nodes",
               "used" => 2,
               "status" => "Active",
             },
          ],
        }],
        "Assets" => [
          {
            "id" => "guid",
            "name" => "testing",
            "entitled" => true,
            "from" => [
              {
                  "license" => "guid",
                  "status" => "expired",
              },
            ],
          }],
        "Software" => [
          {
            "id" => "guid",
            "name" => "testing",
            "entitled" => true,
            "from" => [
              {
                  "license" => "guid",
                  "status" => "expired",
              },
            ],
          }],
        "Features" => [
          {
            "id" => "guid",
            "name" => "testing",
            "entitled" => true,
            "from" => [
              {
                  "license" => "guid",
                  "status" => "expired",
              },
            ],
          }],
        "Services" => [
          {
            "id" => "guid",
            "name" => "testing",
            "entitled" => true,
            "from" => [
              {
                  "license" => "guid",
                  "status" => "expired",
              },
            ],
          }],
        }
    }

    before do
      stub_request(:get, "#{ChefLicensing::Config.license_server_url}/desc")
        .with(query: { licenseId: license_keys.join(","), entitlementId: ChefLicensing::Config.chef_entitlement_id })
        .to_return(body: { data: describe_api_data, status_code: 200 }.to_json,
                   headers: { content_type: "application/json" })
    end

    it "displays the information about the license keys without errors" do
      expect { described_class.new(opts_for_llk).display }.to_not raise_error
      expect(output_stream.string).to include("+------------ License Information ------------+")
      expect(output_stream.string).to include("License Key     :")
      expect(output_stream.string).to include("Type            :")
    end
  end

  describe "when the information is not fetched correctly from the server" do
    let(:license_keys) {
      ["tmns-bea68bbb-1e85-44ea-8b98-a654b011174b-4227"]
    }

    let(:opts_for_llk) {
      {
        output: output_stream,
        license_keys: license_keys,
      }
    }

    before do
      stub_request(:get, "#{ChefLicensing::Config.license_server_url}/desc")
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

    it "exits with error message about LicenseKeyNotFetchedError" do
      expect { described_class.new(opts_for_llk).display }.to raise_error(SystemExit)
      expect(output_stream.string).to include("Error occured while fetching license keys from disk")
    end
  end

  describe "when there are license_keys on the system and overview of the license is fetched" do
    let(:license_keys) {
      ["tmns-bea68bbb-1e85-44ea-8b98-a654b011174b-4227"]
    }

    let(:opts_for_llk) {
      {
        output: output_stream,
        license_keys: license_keys,
      }
    }

    let(:describe_api_data) {
      {
        "license" => [{
          "licenseKey" => "guid",
          "serialNumber" => "testing",
          "name" => "testing",
          "status" => "active",
          "start" => "2022-12-02",
          "end" => "2023-12-02",
          "licenseType" => "trial",
          "limits" => [
             {
              "testing" => "software",
               "id" => "guid",
               "amount" => 2,
               "measure" => "nodes",
               "used" => 2,
               "status" => "Active",
             },
          ],
        }],
        "Assets" => [
          {
            "id" => "guid",
            "name" => "testing",
            "entitled" => true,
            "from" => [
              {
                  "license" => "guid",
                  "status" => "expired",
              },
            ],
          }],
        "Software" => [
          {
            "id" => "guid",
            "name" => "testing",
            "entitled" => true,
            "from" => [
              {
                  "license" => "guid",
                  "status" => "expired",
              },
            ],
          }],
        "Features" => [
          {
            "id" => "guid",
            "name" => "testing",
            "entitled" => true,
            "from" => [
              {
                  "license" => "guid",
                  "status" => "expired",
              },
            ],
          }],
        "Services" => [
          {
            "id" => "guid",
            "name" => "testing",
            "entitled" => true,
            "from" => [
              {
                  "license" => "guid",
                  "status" => "expired",
              },
            ],
          }],
        }
    }

    before do
      stub_request(:get, "#{ChefLicensing::Config.license_server_url}/desc")
        .with(query: { licenseId: license_keys.join(","), entitlementId: ChefLicensing::Config.chef_entitlement_id })
        .to_return(body: { data: describe_api_data, status_code: 200 }.to_json,
                   headers: { content_type: "application/json" })
    end

    it "displays an overview information about the license keys without errors" do
      expect { described_class.new(opts_for_llk).display_overview }.to_not raise_error
      expect(output_stream.string).to include("License Details")
      expect(output_stream.string).to include("Validity         :")
      expect(output_stream.string).to include("No. Of Units     :")
    end
  end
end