require "spec_helper"
require "chef-licensing/api/describe"
require "chef-licensing/config"

RSpec.describe ChefLicensing::Api::Describe do

  let(:license_keys) {
    ["tmns-bea68bbb-1e85-44ea-8b98-a654b011174b-4227"]
  }

  before do
    ChefLicensing.configure do |conf|
      conf.chef_product_name = "inspec"
      conf.chef_entitlement_id = "testing_entitlement_id"
      conf.license_server_url = "http://localhost-license-server/License"
    end
  end

  let(:describe_api_data) {
    {
      "license" => [{
        "licenseKey" => "guid",
        "serialNumber" => "testing",
        "licenseType" => "testing",
        "status" => "active",
        "start" => "2022-12-02",
        "end" => "2023-12-02",
        "limits" => [
           {
            "testing" => "software",
             "id" => "guid",
             "amount" => 2,
             "measure" => 2,
             "used" => 2,
             "status" => "Active",
           },
        ],
      }],
      "Assets" => [
        {
          "id" => "guid",
          "name" => "testing",
          "entitled" => true,
          "from" => [
            {
                "license" => "guid",
                "status" => "expired",
            },
          ],
        }],
      "Software" => [
        {
          "id" => "guid",
          "name" => "testing",
          "entitled" => true,
          "from" => [
            {
                "license" => "guid",
                "status" => "expired",
            },
          ],
        }],
      "Features" => [
        {
          "id" => "guid",
          "name" => "testing",
          "entitled" => true,
          "from" => [
            {
                "license" => "guid",
                "status" => "expired",
            },
          ],
        }],
      "Services" => [
        {
          "id" => "guid",
          "name" => "testing",
          "entitled" => true,
          "from" => [
            {
                "license" => "guid",
                "status" => "expired",
            },
          ],
        }],
      }
  }

  let(:describe_api_invalid_response) {
    {
      "data": {
          "license": nil,
          "Assets": nil,
          "Software": nil,
          "Features": nil,
          "Services": nil,
      },
      "message": "",
      "status": 200,
    }
  }

  subject { described_class.list(license_keys: license_keys) }

  describe ".list" do

    context "when license is valid" do
      before do
        stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/desc")
          .with(query: { licenseId: license_keys.join(","), entitlementId: ChefLicensing::Config.chef_entitlement_id })
          .to_return(body: { data: describe_api_data, status_code: 200 }.to_json,
                    headers: { content_type: "application/json" })
      end

      it { is_expected.to be_truthy }
    end

    context "when license is invalid" do
      let(:error_message) { "Invalid licenses" }
      before do
        stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/desc")
          .with(query: { licenseId: license_keys.join(","), entitlementId: ChefLicensing::Config.chef_entitlement_id })
          .to_return(body: { data: false, message: error_message, status_code: 400 }.to_json,
                     headers: { content_type: "application/json" })
      end

      it { expect { subject }.to raise_error(ChefLicensing::DescribeError, error_message) }
    end

    context "when api response is invalid with status code of 200 - Part 1" do
      let(:error_message) { "No license details found for the given license keys" }
      before do
        stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/desc")
          .with(query: { licenseId: license_keys.join(","), entitlementId: ChefLicensing::Config.chef_entitlement_id })
          .to_return(body: { data: describe_api_invalid_response, message: error_message, status_code: 200 }.to_json,
                     headers: { content_type: "application/json" })
      end

      it { expect { subject }.to raise_error(ChefLicensing::DescribeError, error_message) }
    end
  end
end
