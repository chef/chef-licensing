require "spec_helper"
require "chef_licensing/api/license_client"
require "chef_licensing/config"

RSpec.describe ChefLicensing::Api::LicenseClient do

  let(:license_keys) {
    ["tmns-bea68bbb-1e85-44ea-8b98-a654b011174b-4227"]
  }

  let(:entitlement_id) {
    "testing_entitlement_id"
  }

  let(:client_data) {
    {
      "Cache" => {
        "LastModified" => "2022-11-01",
        "EvaluatedOn" => "2022-11-01",
        "Expires" => "2024-11-01",
        "CacheControl" => "2022-11-01",
      },
      "Client" => {
        "license" => "Trial",
        "status" => "Active",
        "changesTo" => "Grace",
        "changesOn" => "2024-11-01",
        "changesIn" => "2 days",
        "usage" => "Active",
        "used" => 2,
        "limit" => 2,
        "measure" => 2,
      },
      "Assets" => [ { "id" => "assetguid1", "name" => "Test Asset 1" }, { "id" => "assetguid2", "name" => "Test Asset 2" } ],
      "Features" => [ { "id" => "featureguid1", "name" => "Test Feature 1" }, { "id" => "featureguid2", "name" => "Test Feature 2" } ],
      "Entitlement" => {
        "id" => "entitlementguid",
        "name" => "Inspec",
        "start" => "2022-11-01",
        "end" => "2024-11-01",
        "licenses" => 2,
        "limits" => [ { "measure" => "nodes", "amount" => 2 } ],
        "entitled" => false,
      },
    }
  }

  subject { described_class.client(license_keys: license_keys, entitlement_id: entitlement_id) }

  describe ".client" do
    before do
      stub_request(:get, "#{ChefLicensing.license_server_url}/client")
        .with(query: { licenseKeys: license_keys, entitlementId: entitlement_id })
        .to_return(body: { data: client_data, status_code: 200 }.to_json,
                   headers: { content_type: "application/json" })
    end
    it { is_expected.to be_truthy }

    context "when license client call raises error" do
      let(:error_message) { "Invalid licenses" }
      before do
        stub_request(:get, "#{ChefLicensing.license_server_url}/client")
        .with(query: { licenseKeys: license_keys, entitlementId: entitlement_id })
          .to_return(body: { data: false, message: error_message, status_code: 400 }.to_json,
                     headers: { content_type: "application/json" })
      end

      it { expect { subject }.to raise_error(ChefLicensing::LicenseClientError, error_message) }
    end
  end
end
