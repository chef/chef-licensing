require "spec_helper"
require_relative "../lib/chef_licensing"
require_relative "../lib/chef_licensing/api/license_feature_entitlement"
require_relative "../lib/chef_licensing/api/license_software_entitlement"
require_relative "../lib/chef_licensing/exceptions/feature_not_entitled"
require_relative "../lib/chef_licensing/exceptions/software_not_entitled"

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
end
