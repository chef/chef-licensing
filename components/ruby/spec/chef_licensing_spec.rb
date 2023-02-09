require "spec_helper"
require_relative "../lib/chef_licensing"
require_relative "../lib/chef_licensing/api/license_feature_entitlement"
require_relative "../lib/chef_licensing/api/license_software_entitlement"
require_relative "../lib/chef_licensing/exceptions/feature_not_entitled"
require_relative "../lib/chef_licensing/exceptions/software_not_entitled"
require "logger"

RSpec.describe ChefLicensing do
  it "has a version number" do
    expect(ChefLicensing::VERSION).not_to be nil
  end

  describe ".check_feature_entitlement!" do
    let(:feature) { "walk-mode" }
    let(:license_keys) {
      %w{tmns-58555821-925e-4a27-8fdc-e79dae5a425b-9763 tmns-58555821-925e-4a27-8fdc-e79dae5a425b-1234}
    }
    subject { described_class.check_feature_entitlement!(feature_name: feature) }

    before do
      allow(ChefLicensing::LicenseKeyFetcher).to receive(:fetch_and_persist).and_return(license_keys)
      allow(described_class).to receive(:licenses).and_return(license_keys)
      allow(ChefLicensing::Api::LicenseFeatureEntitlement).to receive(:check_entitlement!)
        .with(license_keys: license_keys, feature_name: feature, feature_id: nil)
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
        allow(ChefLicensing::Api::LicenseFeatureEntitlement).to receive(:check_entitlement!)
          .with(license_keys: license_keys, feature_name: feature, feature_id: nil)
          .and_raise(ChefLicensing::FeatureNotEntitled)
      end

      it { expect { subject }.to raise_error(ChefLicensing::FeatureNotEntitled) }
    end
  end

  describe ".check_software_entitlement!" do
    let(:software_name) { "foo" }
    let(:license_keys) {
      %w{tmns-58555821-925e-4a27-8fdc-e79dae5a425b-9763 tmns-58555821-925e-4a27-8fdc-e79dae5a425b-1234}
    }
    subject { described_class.check_software_entitlement!(software_entitlement_name: software_name) }

    before do
      allow(ChefLicensing::LicenseKeyFetcher).to receive(:fetch_and_persist).and_return(license_keys)
      allow(described_class).to receive(:licenses).and_return(license_keys)
      allow(ChefLicensing::Api::LicenseSoftwareEntitlement).to receive(:check!)
        .with(license_keys: license_keys, software_entitlement_name: software_name, software_entitlement_id: nil)
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

      before do
        allow(ChefLicensing::Api::LicenseSoftwareEntitlement).to receive(:check!)
          .with(license_keys: license_keys, software_entitlement_name: software_name, software_entitlement_id: nil)
          .and_raise(ChefLicensing::SoftwareNotEntitled)
      end

      it { expect { subject }.to raise_error(ChefLicensing::SoftwareNotEntitled) }
    end
  end

  describe ".configure" do

    let(:license_server_url) { "https://license-server.example.com" }
    let(:license_server_api_key) { "1234567890" }
    let(:air_gap_status) { false }
    let(:chef_product_name) { "chef" }
    let(:chef_entitlement_id) { "0000-1111-2222-3333" }
    let(:logger) { Logger.new(STDOUT) }

    before do
      described_class.configure do |config|
        config.license_server_url = "https://license-server.example.com"
        config.license_server_api_key = "1234567890"
        config.air_gap_status = false
        config.chef_product_name = "chef"
        config.chef_entitlement_id = "0000-1111-2222-3333"
        config.logger = logger
      end
    end

    it "sets all the configuration values" do
      expect(ChefLicensing::Config.license_server_url).to eq(license_server_url)
      expect(ChefLicensing::Config.license_server_api_key).to eq(license_server_api_key)
      expect(ChefLicensing::Config.air_gap_detected?).to eq(false)
      expect(ChefLicensing::Config.chef_product_name).to eq(chef_product_name)
      expect(ChefLicensing::Config.chef_entitlement_id).to eq(chef_entitlement_id)
      expect(ChefLicensing::Config.logger).to eq(logger)
    end
  end
end
