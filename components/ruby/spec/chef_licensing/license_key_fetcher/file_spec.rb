require "spec_helper"
require "tmpdir"
require "chef_licensing/license_key_fetcher/file"

RSpec.describe ChefLicensing::LicenseKeyFetcher::File do
  let(:fixture_dir) { "spec/fixtures" }
  let(:license_key_file) { "license_key.yaml" }
  let(:unsupported_vesion_license_dir) { "spec/fixtures/unsupported_version_license" }
  let(:multiple_keys_license_dir) { "spec/fixtures/multiple_license_keys_license" }

  describe "#fetch" do
    it "returns license key from file" do
      file_fetcher = ChefLicensing::LicenseKeyFetcher::File.new({ dir: fixture_dir })
      expect(file_fetcher.fetch).to include("12345678")
    end

    it "returns false when license key is not persisted" do
      Dir.mktmpdir do |tmpdir|
        file_fetcher = ChefLicensing::LicenseKeyFetcher::File.new({ dir: tmpdir })
        expect(file_fetcher.fetch).to eq(false)
        expect(file_fetcher.persisted?).to eq(false)
      end
    end

    it "raises error for unsupported version of license file with wrong version" do
      Dir.mktmpdir do |tmpdir|
        file_fetcher = ChefLicensing::LicenseKeyFetcher::File.new({ dir: unsupported_vesion_license_dir })
        expect { file_fetcher.fetch }.to raise_error(RuntimeError, /License File version 10.0.0 not supported./)
      end
    end

    it "returns multiple license keys from a license file" do
      file_fetcher = ChefLicensing::LicenseKeyFetcher::File.new({ dir: multiple_keys_license_dir })
      expect(file_fetcher.fetch).to eq(%w{12345678 10101010})
    end
  end

  describe "#persist" do
    it "stores license key in file" do
      Dir.mktmpdir do |tmpdir|
        file_fetcher = ChefLicensing::LicenseKeyFetcher::File.new({ dir: tmpdir })
        file_fetcher.persist("2345678", "Test-app", "0.1.0")
        expect(file_fetcher.fetch).to eq(["2345678"])
        expect(file_fetcher.persisted?).to eq(true)
      end
    end

    it "stores multiple license keys in file" do
      Dir.mktmpdir do |tmpdir|
        file_fetcher = ChefLicensing::LicenseKeyFetcher::File.new({ dir: tmpdir })
        file_fetcher.persist("23456789", "Test-app", "0.1.0")
        file_fetcher.persist("12345678", "Test-app", "0.1.0")
        expect(file_fetcher.fetch).to eq(%w{23456789 12345678})
        expect(file_fetcher.persisted?).to eq(true)
      end
    end
  end
end