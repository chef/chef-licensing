require "chef_licensing/license"
require "chef_licensing/config"
require "spec_helper"

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
        "entitled" => false,
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
             "software" => "Inspec",
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
          "entitled" => true,
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
          "entitled" => true,
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
          "entitled" => true,
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
          "entitled" => true,
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
      license = ChefLicensing::License.new(data: client_data, product_name: ChefLicensing.chef_product_name, api_parser: ChefLicensing::Api::Parser::Client)

      expect(license.id).to eq nil
      expect(license.status.downcase).to eq "active"
      expect(license.license_type).to eq "Trial"
      expect(license.expiration_date).to eq "2024-11-01"
      expect(license.expiration_status).to eq "Grace"
      expect(license.feature_entitlements.length).to eq 2
      expect(license.software_entitlements.length).to eq 1
      expect(license.asset_entitlements.length).to eq 2
      expect(license.limits.length).to eq 1

      # Each feature entitlement data test
      expect(license.feature_entitlements[0].id).to eq "featureguid1"
      expect(license.feature_entitlements[0].name).to eq "Test Feature 1"
      expect(license.feature_entitlements[1].id).to eq "featureguid2"
      expect(license.feature_entitlements[1].name).to eq "Test Feature 2"

      # Each asset entitlement data test
      expect(license.asset_entitlements[0].id).to eq "assetguid1"
      expect(license.asset_entitlements[0].name).to eq "Test Asset 1"
      expect(license.asset_entitlements[1].id).to eq "assetguid2"
      expect(license.asset_entitlements[1].name).to eq "Test Asset 2"

      # Software entitlement data test
      expect(license.software_entitlements[0].id).to eq "entitlementguid"
      expect(license.software_entitlements[0].name).to eq "Inspec"
      expect(license.software_entitlements[0].entitled).to eq false
      expect(license.software_entitlements[0].status).to eq "active"

      # License limit data test
      expect(license.limits[0].usage_status.downcase).to eq "active"
      expect(license.limits[0].usage_limit).to eq 2
      expect(license.limits[0].usage_measure).to eq 2
      expect(license.limits[0].used).to eq 2
      expect(license.limits[0].software).to eq "inspec"
    end

    it "does not break parsing with empty data" do
      license = ChefLicensing::License.new(data: {}, product_name: ChefLicensing.chef_product_name, api_parser: ChefLicensing::Api::Parser::Client)
      expect(license.id).to eq nil
      expect(license.status).to eq nil
      expect(license.license_type).to eq nil
      expect(license.expiration_date).to eq nil
      expect(license.expiration_status).to eq nil
      expect(license.feature_entitlements.length).to eq 0
      expect(license.software_entitlements.length).to eq 0
      expect(license.asset_entitlements.length).to eq 0
      expect(license.limits.length).to eq 0
    end
  end

  describe "initialising object using describe api parser" do
    it "access license data successfully" do
      license = ChefLicensing::License.new(data: describe_data, product_name: ChefLicensing.chef_product_name, api_parser: ChefLicensing::Api::Parser::Describe)
      expect(license.id).to eq "guidlicensekey"
      expect(license.status.downcase).to eq "active"
      expect(license.license_type).to eq "Trial"
      expect(license.expiration_date).to eq "2023-12-02"
      expect(license.expiration_status).to eq nil
      expect(license.feature_entitlements.length).to eq 1
      expect(license.software_entitlements.length).to eq 1
      expect(license.asset_entitlements.length).to eq 1
      expect(license.limits.length).to eq 1

      # Feature entitlement data test
      expect(license.feature_entitlements[0].id).to eq "featureguid"
      expect(license.feature_entitlements[0].name).to eq "Testing Feature"
      expect(license.feature_entitlements[0].entitled).to eq true
      expect(license.feature_entitlements[0].status).to eq "expired"

      # Asset entitlement data test
      expect(license.asset_entitlements[0].id).to eq "assetguid"
      expect(license.asset_entitlements[0].name).to eq "Testing Asset"
      expect(license.asset_entitlements[0].entitled).to eq true
      expect(license.asset_entitlements[0].status).to eq "expired"

      # Software entitlement data test
      expect(license.software_entitlements[0].id).to eq "softwareguid"
      expect(license.software_entitlements[0].name).to eq "Testing Software"
      expect(license.software_entitlements[0].entitled).to eq true
      expect(license.software_entitlements[0].status).to eq "expired"

      # License limit data test
      expect(license.limits[0].usage_status.downcase).to eq "active"
      expect(license.limits[0].usage_limit).to eq 2
      expect(license.limits[0].usage_measure).to eq 2
      expect(license.limits[0].used).to eq 2
      expect(license.limits[0].software).to eq "Inspec"
    end

    it "does not break parsing with empty data" do
      license = ChefLicensing::License.new(data: {}, product_name: ChefLicensing.chef_product_name, api_parser: ChefLicensing::Api::Parser::Describe)
      expect(license.id).to eq nil
      expect(license.status).to eq nil
      expect(license.license_type).to eq nil
      expect(license.expiration_date).to eq nil
      expect(license.expiration_status).to eq nil
      expect(license.feature_entitlements.length).to eq 0
      expect(license.software_entitlements.length).to eq 0
      expect(license.asset_entitlements.length).to eq 0
      expect(license.limits.length).to eq 0
    end
  end
end