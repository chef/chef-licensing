require "spec_helper"
require "chef-licensing/api/list_licenses"
require "chef-licensing/context"

RSpec.describe ChefLicensing::Api::ListLicenses do
  let(:valid_list_licenses_api_response) { File.read("spec/fixtures/api_response_data/valid_list_licenses_api_response.json") }
  let(:invalid_list_licenses_api_response) { File.read("spec/fixtures/api_response_data/invalid_list_licenses_api_response.json") }
  let(:output) { StringIO.new }
  let(:logger) {
    log = Object.new
    log.extend(Mixlib::Log)
    log.init(output)
    log
  }
  let(:licenses_list) { ["free-42727540-ddc8-4d4b-0000-80662e03cd73-0000"] }

  context "when the licensing server is local, it returns a valid response" do

    before do
      ChefLicensing.configure do |config|
        config.logger = logger
        config.output = output
        config.license_server_url = "http://localhost-license-server/License"
        config.license_server_url_check_in_file = true
        config.chef_product_name = "inspec"
        config.chef_entitlement_id = "3ff52c37-e41f-4f6c-ad4d-365192205968"
      end
    end

    it "returns a list of licenses" do
      stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/listLicenses")
        .to_return(body: valid_list_licenses_api_response,
                   headers: { content_type: "application/json" })

      expect(ChefLicensing::Api::ListLicenses.info).to eq(licenses_list)
      expect(ChefLicensing::Context.local_licensing_service?).to eq(true)
    end
  end

  context "when the licensing server is global, it raises an error" do

    before do
      ChefLicensing.configure do |config|
        config.is_local_license_service = nil
        config.license_server_url = "http://globalhost-license-server/License"
        config.license_server_url_check_in_file = true
      end
    end

    it "raises and error" do
      stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/listLicenses")
        .to_return(body: invalid_list_licenses_api_response,
                    headers: { content_type: "application/json" })
      expect { ChefLicensing::Api::ListLicenses.info }.to raise_error(ChefLicensing::ListLicensesError, /You are not authorized to access this resource/)
      expect(ChefLicensing::Context.local_licensing_service?).to eq(false)
    end
  end

end