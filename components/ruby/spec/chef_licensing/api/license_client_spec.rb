require "spec_helper"
require "chef_licensing/api/license_client"
require "chef_licensing/config"

RSpec.describe ChefLicensing::Api::LicenseClient do

  let(:license_keys) {
    ["tmns-bea68bbb-1e85-44ea-8b98-a654b011174b-4227"]
  }

  let(:opts) {
    {
      env_vars: {
        "CHEF_LICENSE_SERVER" => "http://localhost-license-server/License",
        "CHEF_LICENSE_SERVER_API_KEY" =>  "xDblv65Xt84wULmc8qTN78a3Dr2OuuKxa6GDvb67",
        "CHEF_PRODUCT_NAME" => "inspec",
        "CHEF_ENTITLEMENT_ID" => "3ff52c37-e41f-4f6c-ad4d-365192205968",
      },
    }
  }

  let(:config) {
    ChefLicensing::Config.clone.instance(opts)
  }

  let(:client_data) {
    {
      "cache": {
        "lastModified": "2023-01-16T12:05:40Z",
        "evaluatedOn": "2023-01-16T12:07:20.114370692Z",
        "expires": "2023-01-17T12:07:20.114370783Z",
        "cacheControl": "private,max-age:42460"
      },
      "client" => {
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
      "assets" => [ { "id" => "assetguid1", "name" => "Test Asset 1" }, { "id" => "assetguid2", "name" => "Test Asset 2" } ],
      "features" => [ { "id" => "featureguid1", "name" => "Test Feature 1" }, { "id" => "featureguid2", "name" => "Test Feature 2" } ],
      "entitlement" => {
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

  subject { described_class.client(license_keys: license_keys, entitlement_id: config.chef_entitlement_id, cl_config: config) }

  describe ".client" do
    before do
      stub_request(:get, "#{config.license_server_url}/client")
        .with(query: { licenseId: license_keys.join(","), entitlementId: config.chef_entitlement_id })
        .to_return(body: { data: client_data, status_code: 200 }.to_json,
                   headers: { content_type: "application/json" })
    end
    it { is_expected.to be_truthy }

    context "when license client call raises error" do
      let(:error_message) { "Invalid licenses" }
      before do
        stub_request(:get, "#{config.license_server_url}/client")
          .with(query: { licenseId: license_keys.join(","), entitlementId: config.chef_entitlement_id })
          .to_return(body: { data: false, message: error_message, status_code: 400 }.to_json,
                     headers: { content_type: "application/json" })
      end

      it { expect { subject }.to raise_error(ChefLicensing::LicenseClientError, error_message) }
    end
  end
end
