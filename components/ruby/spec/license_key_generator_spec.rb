require "spec_helper"
require_relative "../lib/chef_licensing/license_key_generator"
require_relative "../lib/chef_licensing"

RSpec.describe ChefLicensing::LicenseKeyGenerator do

  before do
    ChefLicensing.configure do |config|
      config.license_server_url = "http://localhost-license-server/License"
      config.license_server_api_key = "xDblv65Xt84wULmc8qTN78a3Dr2OuuKxa6GDvb67"
    end
  end

  let(:expected_license_key) {
    "tmns-90564f0a-ad22-482f-b57d-569f3fb1c11e-6620"
  }

  let(:expected_response) {
    {
      "delivery": "RealTime",
      "licenseId": expected_license_key,
      "message": "Success",
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
      first_name: params[:first_name],
      last_name: params[:last_name],
      email_id: params[:email_id],
      product: params[:product],
      company: params[:company],
      phone: params[:phone],
    }
  }

  let(:api_key) {
    ChefLicensing::Config.license_server_api_key
  }

  let(:headers) {
    { 'x-api-key': api_key }
  }

  subject { described_class.generate!(params) }

  describe ".generate!" do
    before do
      stub_request(:post, "#{ChefLicensing::Config.license_server_url}/v1/triallicense")
        .with(body: payload.to_json, headers: headers)
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
        stub_request(:post, "#{ChefLicensing::Config.license_server_url}/v1/triallicense")
          .with(body: payload.to_json, headers: headers)
          .to_return(body: expected_response, headers: { content_type: "application/json" }, status: 400)
      end

      it { expect { subject }.to raise_error(ChefLicensing::LicenseGenerationFailed) }
    end

    context "when invalid token is set" do
      let(:api_key) {
        "dummy token"
      }

      let(:expected_response) {
        { "message": "Forbidden" }.to_json
      }

      before do
        ChefLicensing.configure do |config|
          config.license_server_api_key = api_key
        end

        stub_request(:post, "#{ChefLicensing::Config.license_server_url}/v1/triallicense")
          .with(body: payload.to_json, headers: headers)
          .to_return(body: expected_response, headers: { content_type: "application/json" }, status: 403)
      end

      it { expect { described_class.generate!(params) }.to raise_error(ChefLicensing::LicenseGenerationFailed) }
    end
  end
end

