require "spec_helper"
require "chef_licensing/api/license_feature_entitlement"
require "chef_licensing/config"
require "chef_licensing"
require "chef_licensing/exceptions/feature_not_entitled"

RSpec.describe ChefLicensing::Api::LicenseFeatureEntitlement do

  let(:feature_name) {
    "Inspec-Parallel"
  }

  let(:payload) {
    {
      featureName: feature_name,
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
          license_key => true,
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
          license_key => false,
        },
      },
      status: 200,
    }
  }

  let(:opts) {
    {
      env_vars: {
        "CHEF_LICENSE_SERVER" => "http://localhost-license-server/License",
        "CHEF_LICENSE_SERVER_API_KEY" =>  "xDblv65Xt84wULmc8qTN78a3Dr2OuuKxa6GDvb67",
      },
    }
  }

  let(:config) { ChefLicensing::Config.clone.instance(opts) }

  subject { described_class.check_entitlement!(license_keys: [license_key], feature_name: feature_name, cl_config: config) }

  describe ".check_entitlement!" do

    context "when checked for feature by name" do
      let(:license_key) {
        "tmns-90564f0a-ad22-482f-b57d-569f3fb1c11e-6620"
      }

      before do
        stub_request(:post, "#{config.license_server_url}/license-service/featurebyname")
          .with(body: payload)
          .to_return(body: successful_response.to_json,
                     headers: { content_type: "application/json" })
      end
      it { is_expected.to be_truthy }

      context "when license is invalid" do
        let(:license_key) {
          "tmns-90564f0a-ad22-482f-b57d-569f3fb1c11e-dummy"
        }

        let(:invalid_license_response) {
          {
            data: {
              error: "license not found",
            },
            status: 400,
          }
        }

        before do
          stub_request(:post, "#{config.license_server_url}/license-service/featurebyname")
            .with(body: payload)
            .to_return(body: invalid_license_response.to_json,
                       headers: { content_type: "application/json" }, status: 400)
        end

        it { expect { subject }.to raise_error(ChefLicensing::RestfulClientError) }
      end

      context "when feature is not entitled to the license" do

        let(:license_key) {
          "tmns-90564f0a-ad22-482f-b57d-569f3fb1c11e-1234"
        }
        let(:feature_name) {
          "Inspec-Parall"
        }

        before do
          stub_request(:post, "#{config.license_server_url}/license-service/featurebyname")
            .with(body: payload)
            .to_return(body: failure_response.to_json,
                       headers: { content_type: "application/json" })
        end

        it { expect { subject }.to raise_error(ChefLicensing::FeatureNotEntitled) }
      end
    end

    context "when checked for feature by ID" do

      let(:license_key) {
        "tmns-90564f0a-ad22-482f-b57d-569f3fb1c11e-6620"
      }

      let(:feature_id) {
        "feature-id"
      }

      let(:payload) {
        {
          featureGuid: feature_id,
          licenseIds: [
            license_key,
          ],
        }
      }
      subject { described_class.check_entitlement!(license_keys: [license_key], feature_id: feature_id, cl_config: config) }

      before do
        stub_request(:post, "#{config.license_server_url}/license-service/featurebyid")
          .with(body: payload)
          .to_return(body: successful_response.to_json,
                     headers: { content_type: "application/json" })
      end
      it { is_expected.to be_truthy }

      context "when license is invalid" do
        let(:license_key) {
          "tmns-90564f0a-ad22-482f-b57d-569f3fb1c11e-dummy"
        }

        let(:invalid_license_response) {
          {
            data: {
              error: "license not found",
            },
            status: 400,
          }
        }

        before do
          stub_request(:post, "#{config.license_server_url}/license-service/featurebyid")
            .with(body: payload)
            .to_return(body: invalid_license_response.to_json,
                       headers: { content_type: "application/json" }, status: 400)
        end

        it { expect { subject }.to raise_error(ChefLicensing::RestfulClientError) }
      end

      context "when feature is not entitled to the license" do

        let(:license_key) {
          "tmns-90564f0a-ad22-482f-b57d-569f3fb1c11e-1234"
        }
        let(:feature_id) {
          "Inspec-Parall-id"
        }

        before do
          stub_request(:post, "#{config.license_server_url}/license-service/featurebyid")
            .with(body: payload)
            .to_return(body: failure_response.to_json,
                       headers: { content_type: "application/json" })
        end

        it { expect { subject }.to raise_error(ChefLicensing::FeatureNotEntitled) }
      end
    end
  end
end

