require "spec_helper"
require"chef_licensing/api/license_software_entitlement"
require "chef_licensing/config"
require "chef_licensing"

RSpec.describe ChefLicensing::Api::LicenseSoftwareEntitlement do
  let(:software_entitlement_name) {
    "Inspec"
  }

  let(:payload) {
    {
      entitlementName: software_entitlement_name,
      licenseIds: [
        license_key,
      ],
    }
  }

  let(:successful_response) {
    {
      data: {
        entitled: true,
        entitledBy: {
          license_key: true,
        },
        limits: {
          license_key:
          {
            name: "InSpec",
            id: "3ff52c37-e41f-4f6c-ad4d-365192205968",
            measure: "node",
            limit: 10,
            grace: {
              limit: 0,
              duration: 0,
            },
            period: {
              start: "2022-10-06",
              end: "2022-11-05",
            },
          },
        },
      },
      status: 200,
    }
  }

  let(:failure_response) {
    {
      data: {
        entitled: false,
        entitledBy: {
          license_key: false,
        },
        limits: {},
      },
      status: 200,
    }
  }

  subject { described_class.check!(license_keys: [license_key], software_entitlement_name: software_entitlement_name) }

  describe "check!" do
    context "when checked for software entitlement by name" do
      let(:license_key) {
        "tmns-90564f0a-ad22-482f-b57d-569f3fb1c11e-6620"
      }

      context "when software is entitled to the license" do
        before do
          stub_request(:post, "#{ChefLicensing.license_server_url}/license-service/entitlementbyname")
            .with(body: payload)
            .to_return(body: successful_response.to_json,
                      headers: { content_type: "application/json" })
        end

        it { is_expected.to be_truthy }
      end

      context "when license is invalid" do
        let(:license_key) {
          "tmns-90564f0a-ad22-482f-b57d-569f3fb1c11e-dummy"
        }

        before do
          stub_request(:post, "#{ChefLicensing.license_server_url}/license-service/entitlementbyname")
            .with(body: payload)
            .to_return(body: failure_response.to_json,
                       headers: { content_type: "application/json" }, status: 200)
        end

        it { expect { subject }.to raise_error(ChefLicensing::SoftwareNotEntitled) }
      end

      context "when software is not entitled to the license" do

        let(:license_key) {
          "tmns-90564f0a-ad22-482f-b57d-569f3fb1c11e-1234"
        }
        let(:software_entitlement_name) {
          "Inspec-Unknown"
        }

        before do
          stub_request(:post, "#{ChefLicensing.license_server_url}/license-service/entitlementbyname")
            .with(body: payload)
            .to_return(body: failure_response.to_json,
                       headers: { content_type: "application/json" })
        end

        it { expect { subject }.to raise_error(ChefLicensing::SoftwareNotEntitled) }
      end

    end

    context "when checked for software entitlement by id" do
      let(:license_key) {
        "tmns-90564f0a-ad22-482f-b57d-569f3fb1c11e-6620"
      }

      let(:software_entitlement_id) {
        "Inspec-software-entitlement-id"
      }

      let(:payload) {
        {
          entitlementGuid: software_entitlement_id,
          licenseIds: [
            license_key,
          ],
        }
      }

      subject { described_class.check!(license_keys: [license_key], software_entitlement_id: software_entitlement_id) }

      context "when software is entitled to the license" do
        before do
          stub_request(:post, "#{ChefLicensing.license_server_url}/license-service/entitlementbyid")
            .with(body: payload)
            .to_return(body: successful_response.to_json,
                      headers: { content_type: "application/json" })
        end

        it { is_expected.to be_truthy }
      end

      context "when license is invalid" do
        let(:license_key) {
          "tmns-90564f0a-ad22-482f-b57d-569f3fb1c11e-dummy"
        }

        before do
          stub_request(:post, "#{ChefLicensing.license_server_url}/license-service/entitlementbyid")
            .with(body: payload)
            .to_return(body: failure_response.to_json,
                       headers: { content_type: "application/json" }, status: 200)
        end

        it { expect { subject }.to raise_error(ChefLicensing::SoftwareNotEntitled) }
      end

      context "when software is not entitled to the license" do

        let(:license_key) {
          "tmns-90564f0a-ad22-482f-b57d-569f3fb1c11e-1234"
        }

        let(:software_entitlement_id) {
          "Unknown-software-id"
        }

        before do
          stub_request(:post, "#{ChefLicensing.license_server_url}/license-service/entitlementbyid")
            .with(body: payload)
            .to_return(body: failure_response.to_json,
                       headers: { content_type: "application/json" })
        end

        it { expect { subject }.to raise_error(ChefLicensing::SoftwareNotEntitled) }
      end

    end
  end
end