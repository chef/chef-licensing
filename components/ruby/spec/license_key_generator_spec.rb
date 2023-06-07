require "spec_helper"
require_relative "../lib/chef-licensing/license_key_generator"
require_relative "../lib/chef-licensing"

RSpec.describe ChefLicensing::LicenseKeyGenerator do

  before do
    ChefLicensing.configure do |config|
      config.license_server_url = "http://localhost-license-server/License"
      config.license_server_url_check_in_file = true
    end
  end

  let(:expected_license_key) {
    "tmns-90564f0a-ad22-482f-b57d-569f3fb1c11e-6620"
  }

  let(:expected_free_license_key) {
    "free-763haha4-31b7-48ee-a9b6-c00d5666f3c4-0000"
  }

  let(:expected_response) {
    {
      "delivery": "RealTime",
      "licenseId": expected_license_key,
      "message": "Success",
      "status_code": 200,
    }.to_json
  }

  let(:expected_free_license_response) {
    {
      "delivery": "RealTime",
      "licenseId": expected_free_license_key,
      "message": "Success",
      "response_code": 1,
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

  let(:bad_params) {
    {
      first_name: "chef_customer",
      last_name: "inspec",
      email_id: "xxxxxxxxx",
      product: "inspec",
      company: "Chef",
      phone: "xxxxx_yyyyy",
    }
  }

  let(:bad_params_response) {
    { "data": { "error": "Invalid Email Id" }, "status": 400 }.to_json
  }

  describe ".generate_trial_license!" do
    context "when params are valid" do
      before do
        stub_request(:post, "#{ChefLicensing::Config.license_server_url}/v1/trial")
          .with(body: payload.to_json)
          .to_return(body: expected_response,
                     headers: { content_type: "application/json" })
      end

      it "should return the license key" do
        expect(described_class.generate_trial_license!(params)).to eq(expected_license_key)
      end
    end

    context "when params are bad" do
      before do
        stub_request(:post, "#{ChefLicensing::Config.license_server_url}/v1/trial")
          .with(body: bad_params.to_json)
          .to_return(body: bad_params_response, headers: { content_type: "application/json" }, status: 400)
      end

      it "should raise an error" do
        expect { described_class.generate_trial_license!(bad_params) }.to raise_error(ChefLicensing::LicenseGenerationFailed)
      end
    end
  end

  describe ".generate_free_license!" do
    context "when params are valid" do
      before do
        stub_request(:post, "#{ChefLicensing::Config.license_server_url}/v1/free")
          .with(body: payload.to_json)
          .to_return(body: expected_free_license_response,
                     headers: { content_type: "application/json" })
      end

      it "should return the license key" do
        expect(described_class.generate_free_license!(params)).to eq(expected_free_license_key)
      end
    end

    context "when params are bad" do
      before do
        stub_request(:post, "#{ChefLicensing::Config.license_server_url}/v1/free")
          .with(body: bad_params.to_json)
          .to_return(body: bad_params_response, headers: { content_type: "application/json" }, status: 400)
      end

      it "should raise an error" do
        expect { described_class.generate_free_license!(bad_params) }.to raise_error(ChefLicensing::LicenseGenerationFailed)
      end
    end
  end
end

