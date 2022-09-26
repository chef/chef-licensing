require "spec_helper"
require "chef_licensing/license_key_fetcher/file"
require "tmpdir"

RSpec.describe ChefLicensing::LicenseKeyFetcher::File do
  let(:fixture_dir) { "spec/fixtures" }
  let(:license_key_file) { "license_key.yaml" }
  let(:unsupported_vesion_license_dir) { "spec/fixtures/unsupported_version_license" }

  describe "#fetch" do
    it "returns license key from file" do
      file_fetcher = ChefLicensing::LicenseKeyFetcher::File.new({ dir: fixture_dir })
      expect(file_fetcher.fetch).to eq("12345678")
    end

    it "returns nil when license key is not persisted" do
      Dir.tmpdir do |tmpdir|
        file_fetcher = ChefLicensing::LicenseKeyFetcher::File.new({ dir: tmpdir })
        expect(file_fetcher.fetch).to eq(nil)
        expect(file_fetcher.persisted?).to eq(false)
      end
    end

    it "raises error for unsupported version of license file with wrong version" do
      Dir.tmpdir do |tmpdir|
        file_fetcher = ChefLicensing::LicenseKeyFetcher::File.new({ dir: unsupported_vesion_license_dir })
        expect { file_fetcher.fetch }.to raise_error(RuntimeError, /License File version 10.0.0 not supported./)
      end
    end
  end

  describe "#persist" do
    it "stores license key in file" do
      Dir.tmpdir do |tmpdir|
        file_fetcher = ChefLicensing::LicenseKeyFetcher::File.new({ dir: tmpdir })
        file_fetcher.persist("2345678", "Test-app", "0.1.0")
        expect(file_fetcher.fetch).to eq("2345678")
        expect(file_fetcher.persisted?).to eq(true)
      end
    end
  end
end