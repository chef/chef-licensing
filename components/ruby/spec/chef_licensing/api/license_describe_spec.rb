require "spec_helper"
require "chef_licensing/api/license_describe"
require "chef_licensing/config"

RSpec.describe ChefLicensing::Api::LicenseDescribe do

  let(:license_keys) {
    ["tmns-bea68bbb-1e85-44ea-8b98-a654b011174b-4227"]
  }

  let(:entitlement_id) {
    "testing_entitlement_id"
  }

  let(:describe_api_data){
    {
      "license" => [{
        "licenseKey" => "guid",
        "serialNumber" => "testing",
        "name" => "testing",
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
      "assets" => [
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
      "software" => [
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
      "features" => [
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
      "services" => [
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

  subject { described_class.list(license_keys: license_keys, entitlement_id: entitlement_id) }

  describe ".list" do
    before do
      stub_request(:get, "#{ChefLicensing.license_server_url}/describe")
        .with(query: { licenseKeys: license_keys, entitlementId: entitlement_id })
        .to_return(body: { data: describe_api_data, status_code: 200 }.to_json,
                   headers: { content_type: "application/json" })
    end
    it { is_expected.to be_truthy }

    context "when license is invalid" do
      let(:error_message) { "Invalid licenses" }
      before do
        stub_request(:get, "#{ChefLicensing.license_server_url}/describe")
        .with(query: { licenseKeys: license_keys, entitlementId: entitlement_id })
          .to_return(body: { data: false, message: error_message, status_code: 400 }.to_json,
                     headers: { content_type: "application/json" })
      end

      it { expect { subject }.to raise_error(ChefLicensing::LicenseDescribeError, error_message) }
    end
  end
end
