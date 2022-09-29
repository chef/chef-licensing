require "spec_helper"
require_relative "../lib/chef_licensing/license_key_generator"
require_relative "../lib/chef_licensing/config"

RSpec.describe ChefLicensing::LicenseKeyGenerator do

  let(:expected_license_key) {
    "tmns-90564f0a-ad22-482f-b57d-569f3fb1c11e-6620"
  }

  let(:expected_response) {
    {
      "delivery": "RealTime",
      "key": expected_license_key,
      "msg": "Success",
      "status_code": 200,
    }.to_json
  }

  let(:params) {
    {
      first_name: "chef_customer",
      last_name: "inspec",
      email_id: "inspec@chef.com",
      product: "inspec",
      company: "Chef",
      phone: "xxxxx_yyyyy",
    }
  }

  let(:payload) {
    {
      firstName: params[:first_name],
      lastName: params[:last_name],
      emailId: params[:email_id],
      product: params[:product],
      company: params[:company],
      phone: params[:phone],
    }
  }

  subject { described_class.generate!(params) }

  describe ".generate!" do
    before do
      stub_request(:post, "#{ChefLicensing::Config::LICENSING_SERVER}/v1/triallicense")
        .with(body: payload.to_json)
        .to_return(body: expected_response,
                   headers: { content_type: "application/json" })
    end
    it { is_expected.to eq(expected_license_key) }

    context "when params are bad" do

      let(:params) {
        {
          first_name: "chef_customer",
          last_name: "inspec",
          email_id: "xxxxxxxxx",
          product: "inspec",
          company: "Chef",
          phone: "xxxxx_yyyyy",
        }
      }

      let(:expected_response) {
        { "data": { "error": "Invalid Email Id" }, "status": 400 }.to_json
      }

      before do
        stub_request(:post, "#{ChefLicensing::Config::LICENSING_SERVER}/v1/triallicense")
          .with(body: payload.to_json)
          .to_return(body: expected_response, headers: { content_type: "application/json" }, status: 400)
      end

      # it { is_expected.to eq(expected_license_key) }
      it { expect { subject }.to raise_error(ChefLicensing::LicenseGenerationFailed) }
    end
  end
end

