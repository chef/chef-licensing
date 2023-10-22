require "spec_helper"
require "chef-licensing/api/client"
require "chef-licensing/config"

RSpec.describe ChefLicensing::Api::Client do

  let(:license_keys) {
    ["tmns-bea68bbb-1e85-44ea-8b98-a654b011174b-4227"]
  }

  before do
    ChefLicensing.configure do |conf|
      conf.license_server_url = "http://localhost-license-server/License"
      conf.license_server_url_check_in_file = true
      conf.chef_product_name = "inspec"
      conf.chef_entitlement_id = "3ff52c37-e41f-4f6c-ad4d-365192205968"
      conf.cache_enabled = false
    end
  end

  let(:client_data) { JSON.parse(File.read("spec/fixtures/api_response_data/valid_client_api_response.json")) }

  subject { described_class.info(license_keys: license_keys, entitlement_id: ChefLicensing::Config.chef_entitlement_id) }

  describe ".info" do
    before do
      stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
        .with(query: { licenseId: license_keys.join(","), entitlementId: ChefLicensing::Config.chef_entitlement_id })
        .to_return(body: { data: client_data, status_code: 200 }.to_json,
                   headers: { content_type: "application/json" })
    end
    it { is_expected.to be_truthy }

    context "when license client call raises error" do
      let(:error_message) { "Invalid licenses" }
      before do
        stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
          .with(query: { licenseId: license_keys.join(","), entitlementId: ChefLicensing::Config.chef_entitlement_id })
          .to_return(body: { data: false, message: error_message, status_code: 400 }.to_json,
                     headers: { content_type: "application/json" })
      end

      it { expect { subject }.to raise_error(ChefLicensing::ClientError, error_message) }
    end
  end
end
