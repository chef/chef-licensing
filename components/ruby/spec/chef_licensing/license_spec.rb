require "chef_licensing/license"

RSpec.describe ChefLicensing::License do
  let(:data) {
    {
      "id": "tmns-bea68bbb-1e85-44ea-8b98-a654b011174b-4227",
      "type": "trial",
      "feature_entitlements": [
        {
          "name": "Inspec-Parallel",
          "id": "c891f0fa-fa71-8b98-b694-7b5462595f35",
          "expiry_date": "2022-11-27",
        },
      ],
      "asset_entitlements": [],
      "software_entitlements": [
        {
          "name": "Automate",
          "id": "c770f0fa-7fa1-4c5b-b694-7b5462595f35",
          "expiry_date": "2022-11-27",
          "measure": "node",
          "limit": 10,
        },
        {
          "name": "Habitat",
          "id": "07f7ab25-6e5d-4e04-b786-a87dabcef659",
          "expiry_date": "2022-11-27",
          "measure": "node",
          "limit": 10,
        },
        {
          "name": "InSpec",
          "id": "3ff52c37-e41f-4f6c-ad4d-365192205968",
          "expiry_date": "2022-11-27",
          "measure": "node",
          "limit": 10,
        },
        {
          "name": "Infra",
          "id": "a5213d76-181f-4924-adba-4b7ed2b098b5",
          "expiry_date": "2022-11-27",
          "measure": "node",
          "limit": 10,
        },
      ],
    }
  }

  describe "initialising object" do
    it "access license data successfully" do
      license = ChefLicensing::License.new(data: data, product_name: "inspec")
      expect(license.id).to eq "tmns-bea68bbb-1e85-44ea-8b98-a654b011174b-4227"
      expect(license.license_type).to eq "trial"
      expect(license.feature_entitlements.length).to eq 1
      expect(license.software_entitlements.length).to eq 4
      expect(license.asset_entitlements.length).to eq 0
    end
  end
end