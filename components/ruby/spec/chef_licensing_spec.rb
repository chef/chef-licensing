require "spec_helper"
require_relative "../lib/chef-licensing"
require_relative "../lib/chef-licensing/api/license_feature_entitlement"
require_relative "../lib/chef-licensing/api/license_software_entitlement"
require_relative "../lib/chef-licensing/exceptions/client_error"

RSpec.describe ChefLicensing do

  let(:logger) { Logger.new(STDOUT) }

  before do
    described_class.configure do |config|
      config.license_server_url = "http://localhost-license-server/License"
      config.license_server_url_check_in_file = true
      config.chef_product_name = "inspec"
      config.chef_entitlement_id = "3ff52c37-e41f-4f6c-ad4d-365192205968"
      config.logger = logger
    end
  end

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
      stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
        .with(query: { licenseId: license_keys.join(","), entitlementId: ChefLicensing::Config.chef_entitlement_id })
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
        stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
          .with(query: { licenseId: license_keys.join(","), entitlementId: ChefLicensing::Config.chef_entitlement_id })
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
      stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
        .with(query: { licenseId: license_keys.join(","), entitlementId: ChefLicensing::Config.chef_entitlement_id })
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
        stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
          .with(query: { licenseId: license_keys.join(","), entitlementId: ChefLicensing::Config.chef_entitlement_id })
          .to_return(body: { data: false, status_code: 400 }.to_json,
                     headers: { content_type: "application/json" })
        allow(ChefLicensing).to receive(:check_software_entitlement!)
          .and_raise(ChefLicensing::ClientError)
      end

      it { expect { subject }.to raise_error(ChefLicensing::ClientError) }
    end
  end

  describe ".configure" do

    let(:license_server_url) { "https://license-server.example.com" }
    let(:chef_product_name) { "chef" }
    let(:chef_entitlement_id) { "0000-1111-2222-3333" }
    let(:logger) { Logger.new(STDOUT) }

    before do
      described_class.configure do |config|
        config.license_server_url = "https://license-server.example.com"
        config.chef_product_name = "chef"
        config.chef_entitlement_id = "0000-1111-2222-3333"
        config.logger = logger
      end
    end

    it "sets all the configuration values" do
      expect(ChefLicensing::Config.license_server_url).to eq(license_server_url)
      expect(ChefLicensing::Config.chef_product_name).to eq(chef_product_name)
      expect(ChefLicensing::Config.chef_entitlement_id).to eq(chef_entitlement_id)
      expect(ChefLicensing::Config.logger).to eq(logger)
    end
  end

  describe ".fetch_and_persist" do
    context "when there is no client error" do
      let(:license_keys) { %w{license_key1 license_key2} }

      before do
        allow(ChefLicensing::LicenseKeyFetcher).to receive(:fetch_and_persist).and_return(license_keys)
      end

      it "fetches and persists the license keys" do
        expect(ChefLicensing.fetch_and_persist).to eq(license_keys)
      end
    end

    context "when there is a client error due to software entitlement" do
      let(:error_message) { "Software is not entitled." }

      before do
        allow(ChefLicensing::LicenseKeyFetcher).to receive(:fetch_and_persist).and_raise(ChefLicensing::ClientError, error_message)
      end

      it "raises a SoftwareNotEntitled exception" do
        expect { ChefLicensing.fetch_and_persist }.to raise_error(ChefLicensing::SoftwareNotEntitled, error_message)
      end
    end

    context "when there is a client error due to unknown reason" do
      before do
        allow(ChefLicensing::LicenseKeyFetcher).to receive(:fetch_and_persist).and_raise(ChefLicensing::ClientError, "Some other error")
      end

      it "raises a ClientError exception" do
        expect { ChefLicensing.fetch_and_persist }.to raise_error(ChefLicensing::ClientError, "Some other error")
      end
    end
  end
end
