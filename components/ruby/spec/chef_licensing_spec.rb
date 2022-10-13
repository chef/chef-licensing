require "spec_helper"
require_relative "../lib/chef_licensing"
require_relative "../lib/chef_licensing/license_feature_entitlement"
require_relative "../lib/chef_licensing/exceptions/invalid_entitlement"

RSpec.describe ChefLicensing do
  it "has a version number" do
    expect(ChefLicensing::VERSION).not_to be nil
  end

  describe ".check_feature_entitlement!" do
    let(:feature) { "walk-mode" }
    let(:license_keys) {
      %w{tmns-58555821-925e-4a27-8fdc-e79dae5a425b-9763 tmns-58555821-925e-4a27-8fdc-e79dae5a425b-1234}
    }
    subject { described_class.check_feature_entitlement!(feature) }

    before do
      allow(described_class).to receive(:licenses).and_return(license_keys)
      allow(ChefLicensing::LicenseFeatureEntitlement).to receive(:check_entitlement!)
        .with(license_keys, feature_name: feature)
        .and_return(true)
    end

    it { is_expected.to eq(true) }
  end

  context "when license keys are invalid" do
    let(:feature) { "fly-mode" }
    let(:license_keys) {
      %w{tmns-58555821-925e-4a27-8fdc-e79dae5a425b-9763}
    }

    let(:invalid_license_id) {
      "tmns-58555821-925e-4a27-8fdc-e79dae5a425b-1234"
    }

    subject { described_class.check_feature_entitlement!(feature) }

    before do
      allow(described_class).to receive(:licenses).and_return(license_keys)
      allow(ChefLicensing::LicenseFeatureEntitlement).to receive(:check_entitlement!)
        .with(invalid_license_id, feature_name: feature)
        .and_raise(ChefLicensing::InvalidEntitlement)
    end

    it { expect { subject }.to raise_error(ChefLicensing::InvalidEntitlement) }
  end
end
