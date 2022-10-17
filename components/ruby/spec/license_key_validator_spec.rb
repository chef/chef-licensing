require "spec_helper"
require_relative "../lib/chef_licensing/license_key_validator"
require_relative "../lib/chef_licensing/config"

RSpec.describe ChefLicensing::LicenseKeyValidator do

  let(:license_key) {
    "tmns-90564f0a-ad22-482f-b57d-569f3fb1c11e-6620"
  }

  subject { described_class.validate!(license_key) }

  describe ".validate!" do
    before do
      stub_request(:get, "#{ChefLicensing::Config.licensing_server}/v1/validate")
        .with(query: { licenseId: license_key })
        .to_return(body: { data: true, message: "License Id is valid", status_code: 200 }.to_json,
                   headers: { content_type: "application/json" })
    end
    it { is_expected.to be_truthy }

    context "when license is in valid" do
      before do
        stub_request(:get, "#{ChefLicensing::Config.licensing_server}/v1/validate")
          .with(query: { licenseId: license_key })
          .to_return(body: { data: false, message: "License Id is invalid", status_code: 200 }.to_json,
                     headers: { content_type: "application/json" })
      end

      it { expect { subject }.to raise_error(ChefLicensing::InvalidLicense) }
    end
  end
end
