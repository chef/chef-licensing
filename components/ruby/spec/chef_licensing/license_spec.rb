require "chef_licensing/license"
require "chef_licensing/api/parser/client" unless defined?(ChefLicensing::Api::Parser::Client)
require "chef_licensing/api/parser/describe" unless defined?(ChefLicensing::Api::Parser::Describe)

RSpec.describe ChefLicensing::License do
  let(:client_data) {
    {
      "Cache" => {
        "LastModified" => "2022-11-01",
        "EvaluatedOn" => "2022-11-01",
        "Expires" => "2024-11-01",
        "CacheControl" => "2022-11-01",
      },
      "Client" => {
        "license" => "Trial",
        "status" => "Active",
        "changesTo" => "Grace",
        "changesOn" => "2024-11-01",
        "changesIn" => "2 days",
        "usage" => "Active",
        "used" => 2,
        "limit" => 2,
        "measure" => 2,
      },
      "Assets" => [ { "id" => "assetguid1", "name" => "Test Asset 1" }, { "id" => "assetguid2", "name" => "Test Asset 2" } ],
      "Features" => [ { "id" => "featureguid1", "name" => "Test Feature 1" }, { "id" => "featureguid2", "name" => "Test Feature 2" } ],
      "Entitlement" => {
        "id" => "entitlementguid",
        "name" => "Inspec",
        "start" => "2022-11-01",
        "end" => "2024-11-01",
        "licenses" => 2,
        "limits" => [ { "measure" => "nodes", "amount" => 2 } ],
        "entitled" => "false",
      },
    }
  }

  let(:describe_data) {
    {
      "license" => {
        "licenseKey" => "guidlicensekey",
        "serialNumber" => "testing",
        "name" => "Trial",
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
      },
      "assets" => [
        {
          "id" => "assetguid",
          "name" => "Testing Asset",
          "entitled" => "true",
          "from" => [
            {
                "license" => "guidlicensekey",
                "status" => "expired",
            },
          ],
        }],
      "software" => [
        {
          "id" => "softwareguid",
          "name" => "Testing Software",
          "entitled" => "true",
          "from" => [
            {
                "license" => "guidlicensekey",
                "status" => "expired",
            },
          ],
        }],
      "features" => [
        {
          "id" => "featureguid",
          "name" => "Testing Feature",
          "entitled" => "true",
          "from" => [
            {
                "license" => "guidlicensekey",
                "status" => "expired",
            },
          ],
        }],
      "services" => [
        {
          "id" => "guid",
          "name" => "testing",
          "entitled" => "true",
          "from" => [
            {
                "license" => "guidlicensekey",
                "status" => "expired",
            },
          ],
        }],
      }
  }

  describe "initialising object using client api parser" do
    it "access license data successfully" do
      license = ChefLicensing::License.new(data: client_data, product_name: "inspec", api_parser: ChefLicensing::Api::Parser::Client)
      expect(license.id).to eq nil
      expect(license.status.downcase).to eq "active"
      expect(license.license_type).to eq "Trial"
      expect(license.expiration_date).to eq "2024-11-01"
      expect(license.expiration_status).to eq "Grace"
      expect(license.feature_entitlements.length).to eq 2
      expect(license.software_entitlements.length).to eq 1
      expect(license.asset_entitlements.length).to eq 2
      expect(license.limits.length).to eq 1
    end
  end

  describe "initialising object using describe api parser" do
    it "access license data successfully" do
      license = ChefLicensing::License.new(data: describe_data, product_name: "inspec", api_parser: ChefLicensing::Api::Parser::Describe)
      expect(license.id).to eq "guidlicensekey"
      expect(license.status.downcase).to eq "active"
      expect(license.license_type).to eq "Trial"
      expect(license.expiration_date).to eq "2023-12-02"
      expect(license.expiration_status).to eq nil
      expect(license.feature_entitlements.length).to eq 1
      expect(license.software_entitlements.length).to eq 1
      expect(license.asset_entitlements.length).to eq 1
      expect(license.limits.length).to eq 1
    end
  end
end