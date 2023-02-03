require "spec_helper"
require_relative "../lib/chef_licensing"
require_relative "../lib/chef_licensing/api/license_feature_entitlement"
require_relative "../lib/chef_licensing/api/license_software_entitlement"
require_relative "../lib/chef_licensing/exceptions/client_error"

RSpec.describe ChefLicensing do

  let(:env_opts) {
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
    ChefLicensing::Config.clone.instance(env_opts)
  }

  let(:client_data) {
    {
      "cache": {
        "lastModified": "2023-01-16T12:05:40Z",
        "evaluatedOn": "2023-01-16T12:07:20.114370692Z",
        "expires": "2023-01-17T12:07:20.114370783Z",
        "cacheControl": "private,max-age:42460",
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
        "id" => "3ff52c37-e41f-4f6c-ad4d-365192205968",
        "name" => "Inspec",
        "start" => "2022-11-01",
        "end" => "2024-11-01",
        "licenses" => 2,
        "limits" => [ { "measure" => "nodes", "amount" => 2 } ],
        "entitled" => false,
      },
    }
  }

  it "has a version number" do
    expect(ChefLicensing::VERSION).not_to be nil
  end

  describe ".check_feature_entitlement!" do
    let(:feature) { "Test Feature 1" }
    let(:license_keys) {
      %w{tmns-58555821-925e-4a27-8fdc-e79dae5a425b-9763 tmns-58555821-925e-4a27-8fdc-e79dae5a425b-1234}
    }
    subject { described_class.check_feature_entitlement!(feature_name: feature, feature_id: nil) }

    before do
      stub_request(:get, "#{config.license_server_url}/client")
        .with(query: { licenseId: license_keys.join(","), entitlementId: config.chef_entitlement_id })
        .to_return(body: { data: client_data, status_code: 200 }.to_json,
                     headers: { content_type: "application/json" })
      allow(ChefLicensing::LicenseKeyFetcher).to receive(:fetch_and_persist).and_return(license_keys)
      allow(described_class).to receive(:licenses).and_return(license_keys)
      allow(ChefLicensing).to receive(:check_feature_entitlement!)
        .with(feature_name: feature, feature_id: nil)
        .and_return(true)
    end

    it { is_expected.to eq(true) }

    context "when license keys are invalid" do
      let(:feature) { "fly-mode" }
      let(:license_keys) {
        [invalid_license_id]
      }

      let(:invalid_license_id) {
        "tmns-58555821-925e-4a27-8fdc-e79dae5a425b-1234"
      }

      before do
        stub_request(:get, "#{config.license_server_url}/client")
          .with(query: { licenseId: license_keys.join(","), entitlementId: config.chef_entitlement_id })
          .to_return(body: { data: false, status_code: 400 }.to_json,
                     headers: { content_type: "application/json" })
        allow(ChefLicensing).to receive(:check_feature_entitlement!)
          .with(feature_name: feature, feature_id: nil)
          .and_raise(ChefLicensing::ClientError)
      end

      it { expect { subject }.to raise_error(ChefLicensing::ClientError) }
    end
  end

  describe ".check_software_entitlement!" do
    let(:license_keys) {
      %w{tmns-58555821-925e-4a27-8fdc-e79dae5a425b-9763 tmns-58555821-925e-4a27-8fdc-e79dae5a425b-1234}
    }
    subject { described_class.check_software_entitlement! }

    before do
      stub_request(:get, "#{config.license_server_url}/client")
        .with(query: { licenseId: license_keys.join(","), entitlementId: config.chef_entitlement_id })
        .to_return(body: { data: client_data, status_code: 200 }.to_json,
                     headers: { content_type: "application/json" })
      allow(ChefLicensing::LicenseKeyFetcher).to receive(:fetch_and_persist).and_return(license_keys)
      allow(described_class).to receive(:licenses).and_return(license_keys)
      allow(ChefLicensing).to receive(:check_software_entitlement!)
        .and_return(true)
    end

    it { is_expected.to eq(true) }

    context "when license keys are invalid" do
      let(:software_name) { "bar" }
      let(:license_keys) {
        [invalid_license_id]
      }

      let(:invalid_license_id) {
        "tmns-58555821-925e-4a27-8fdc-e79dae5a425b-1234"
      }

      let(:invalid_license_client_data) {
        {
          "data": false,
          "message": "invalid licenseId",
          "status_code": 400,
        }
      }

      before do
        stub_request(:get, "#{config.license_server_url}/client")
          .with(query: { licenseId: license_keys.join(","), entitlementId: config.chef_entitlement_id })
          .to_return(body: { data: false, status_code: 400 }.to_json,
                     headers: { content_type: "application/json" })
        allow(ChefLicensing).to receive(:check_software_entitlement!)
          .and_raise(ChefLicensing::ClientError)
      end

      it { expect { subject }.to raise_error(ChefLicensing::ClientError) }
    end
  end
end
