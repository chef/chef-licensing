require "chef_licensing/list_license_keys"
require "chef_licensing/config"
require "spec_helper"

RSpec.describe ChefLicensing::ListLicenseKeys do
  let(:opts) {
    {
      env_vars: {
        "CHEF_LICENSE_SERVER" => "http://localhost-license-server/License",
        "CHEF_LICENSE_SERVER_API_KEY" =>  "xDblv65Xt84wULmc8qTN78a3Dr2OuuKxa6GDvb67",
        "CHEF_PRODUCT_NAME" => "inspec",
        "CHEF_ENTITLEMENT_ID" => "testing_entitlement_id",
      },
      logger: Logger.new(StringIO.new),
    }
  }
  let(:cl_config) {
    ChefLicensing::Config.clone.instance(opts)
  }

  let(:output_stream) {
    StringIO.new
  }

  describe "when there are no license_keys on the system" do
    let(:license_keys) { [] }

    let(:opts_for_llk) {
      {
        output: output_stream,
        license_keys: license_keys,
        cl_config: cl_config,
      }
    }

    it "exits with no information about licenses" do
      expect { described_class.new(opts_for_llk).display }.to raise_error(SystemExit)
      expect(output_stream.string).to include("No license keys found on disk.")
    end
  end

  describe "when there are license_keys on the system" do
    let(:license_keys) {
      ["tmns-bea68bbb-1e85-44ea-8b98-a654b011174b-4227"]
    }

    let(:opts_for_llk) {
      {
        output: output_stream,
        license_keys: license_keys,
        cl_config: cl_config,
      }
    }


    let(:describe_api_data) {
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

    before do
      stub_request(:get, "#{cl_config.license_server_url}/desc")
        .with(query: { licenseId: license_keys.join(","), entitlementId: cl_config.chef_entitlement_id })
        .to_return(body: { data: describe_api_data, status_code: 200 }.to_json,
                   headers: { content_type: "application/json" })
    end

    it "displays the information about the license keys without errors" do
      expect { described_class.new(opts_for_llk).display }.to_not raise_error
      expect(output_stream.string).to include("+------------ Licenses Information ------------+")
      expect(output_stream.string).to include("License Key     :")
      expect(output_stream.string).to include("Type            :")
    end
  end

  describe "when the information is not fetched correctly from the server" do
    let(:license_keys) {
      ["tmns-bea68bbb-1e85-44ea-8b98-a654b011174b-4227"]
    }

    let(:opts_for_llk) {
      {
        output: output_stream,
        license_keys: license_keys,
        cl_config: cl_config,
      }
    }

    before do
      stub_request(:get, "#{cl_config.license_server_url}/desc")
        .with(query: { licenseId: license_keys.join(","), entitlementId: cl_config.chef_entitlement_id })
        .to_return(body: { status_code: 404 }.to_json,
                   headers: { content_type: "application/json" })
    end

    it "exits with error message about LicenseDescribeError" do
      expect { described_class.new(opts_for_llk).display }.to raise_error(SystemExit)
      expect(output_stream.string).to include("Error occured while fetching licenses information: ChefLicensing::LicenseDescribeError")
    end
  end

  describe "when the license key is not fetched correctly from the system" do
    let(:unsupported_version_license_dir) { "spec/fixtures/unsupported_version_license" }
    let(:opts_for_llk) {
      {
        output: output_stream,
        cl_config: cl_config,
        dir: unsupported_version_license_dir,
      }
    }

    it "exits with error message about LicenseKeyNotFetchedError" do
      expect { described_class.new(opts_for_llk).display }.to raise_error(SystemExit)
      expect(output_stream.string).to include("Error occured while fetching license keys from disk")
    end
  end
end