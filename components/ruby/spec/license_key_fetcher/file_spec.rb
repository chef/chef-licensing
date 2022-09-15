require "spec_helper"
require "chef_licensing/license_key_fetcher/file"

RSpec.describe ChefLicensing::LicenseKeyFetcher::File do
  let(:fixture_dir) { "../fixtures" }
  let(:license_key_file) { "license_key.yaml" }
  let(:test_chef_dir) { ".test-chef" }

  describe "#fetch" do
    it "returns license key from file" do
      file_fetcher = ChefLicensing::LicenseKeyFetcher::File.new({ dir: fixture_dir })
      expect(file_fetcher.fetch).to eq("12345678")
    end
  end

  describe "#persist" do
    it "stores license key in file" do
      file_fetcher = ChefLicensing::LicenseKeyFetcher::File.new({ dir: ".test-chef" })
      file_fetcher.persist("2345678", "Test-app", "0.1.0")
      expect(file_fetcher.fetch).to eq("2345678")
      expect(file_fetcher.persisted?).to eq(true)
      # TBD
      # need to improve this step - by making this part of spec helper
      # should be able to create license throughout the test suit and delete the test directory
      FileUtils.rm_rf(test_chef_dir)
    end
  end
end