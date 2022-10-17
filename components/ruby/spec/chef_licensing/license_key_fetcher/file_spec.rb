require "spec_helper"
require "tmpdir"
require "chef_licensing/license_key_fetcher/file"

RSpec.describe ChefLicensing::LicenseKeyFetcher::File do
  let(:fixture_dir) { "spec/fixtures" }
  let(:license_key_file) { "licenses.yaml" }
  let(:unsupported_vesion_license_dir) { "spec/fixtures/unsupported_version_license" }
  let(:multiple_keys_license_dir) { "spec/fixtures/multiple_license_keys_license" }

  describe "#fetch" do
    it "returns license key from file" do
      file_fetcher = ChefLicensing::LicenseKeyFetcher::File.new({ dir: fixture_dir })
      expect(file_fetcher.fetch).to include("tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150")
    end

    it "returns an empty array when license key is not persisted" do
      Dir.mktmpdir do |tmpdir|
        file_fetcher = ChefLicensing::LicenseKeyFetcher::File.new({ dir: tmpdir })
        expect(file_fetcher.fetch).to eq([])
        expect(file_fetcher.persisted?).to eq(false)
      end
    end

    it "raises error for unsupported version of license file with wrong version" do
      Dir.mktmpdir do |tmpdir|
        file_fetcher = ChefLicensing::LicenseKeyFetcher::File.new({ dir: unsupported_vesion_license_dir })
        expect { file_fetcher.fetch }.to raise_error(RuntimeError, /License File version 0.0.0 not supported./)
      end
    end

    it "returns multiple license keys from a license file" do
      file_fetcher = ChefLicensing::LicenseKeyFetcher::File.new({ dir: multiple_keys_license_dir })
      expect(file_fetcher.fetch).to eq(%w{tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150 tmns-0f76efaf-c45c-4d92-86b2-2d144ce73dfa-150})
    end
  end

  describe "#persist" do
    it "stores license key in file" do
      Dir.mktmpdir do |tmpdir|
        file_fetcher = ChefLicensing::LicenseKeyFetcher::File.new({ dir: tmpdir })
        file_fetcher.persist("tmns-0f76efaf-d45d-4d92-86b2-2d144ce73dfa-150")
        expect(file_fetcher.fetch).to eq(["tmns-0f76efaf-d45d-4d92-86b2-2d144ce73dfa-150"])
        expect(file_fetcher.persisted?).to eq(true)
      end
    end

    it "stores multiple license keys in file" do
      Dir.mktmpdir do |tmpdir|
        file_fetcher = ChefLicensing::LicenseKeyFetcher::File.new({ dir: tmpdir })
        file_fetcher.persist("tmns-0f76efaf-e45e-4d92-86b2-2d144ce73dfa-150")
        file_fetcher.persist("tmns-0f76efaf-f45f-4d92-86b2-2d144ce73dfa-150")
        expect(file_fetcher.fetch).to eq(%w{tmns-0f76efaf-e45e-4d92-86b2-2d144ce73dfa-150 tmns-0f76efaf-f45f-4d92-86b2-2d144ce73dfa-150})
        expect(file_fetcher.persisted?).to eq(true)
      end
    end
  end
end
