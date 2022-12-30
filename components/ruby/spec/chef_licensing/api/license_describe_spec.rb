require "spec_helper"
require "chef_licensing/api/license_describe"
require "chef_licensing/config"

RSpec.describe ChefLicensing::Api::LicenseDescribe do

  let(:license_keys) {
    ["tmns-bea68bbb-1e85-44ea-8b98-a654b011174b-4227"]
  }

  let(:entitlement_id) {
    "testing_entitlement_id"
  }

  subject { described_class.list(license_keys: license_keys, entitlement_id: entitlement_id) }

  describe ".list" do
    before do
      stub_request(:get, "#{ChefLicensing.license_server_url}/describe")
        .with(query: { licenseKeys: license_keys, entitlementId: entitlement_id })
        .to_return(body: { message: "License Id is valid", status_code: 200 }.to_json,
                   headers: { content_type: "application/json" })
    end
    # it { is_expected.to be_truthy } TODO after API is available

    context "when license is invalid" do
      # TODO after API is available
    end
  end
end
