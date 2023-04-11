require "spec_helper"
require "tmpdir"
require "chef-licensing/license_key_fetcher/file"
require "logger"
require "chef-licensing"

RSpec.describe ChefLicensing::LicenseKeyFetcher::File do
  let(:fixture_dir) { "spec/fixtures" }
  let(:license_key_file) { "licenses.yaml" }
  let(:unsupported_vesion_license_dir) { "spec/fixtures/unsupported_version_license" }
  let(:multiple_keys_license_dir) { "spec/fixtures/multiple_license_keys_license" }
  let(:logger) { double("Logger") }

  before do
    ChefLicensing.configure do |config|
      config.logger = logger
    end
  end

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
        file_fetcher.persist("tmns-0f76efaf-d45d-4d92-86b2-2d144ce73dfa-150", "trial")
        expect(file_fetcher.fetch).to eq(["tmns-0f76efaf-d45d-4d92-86b2-2d144ce73dfa-150"])
        expect(file_fetcher.persisted?).to eq(true)
      end
    end

    it "stores multiple license keys in file" do
      Dir.mktmpdir do |tmpdir|
        file_fetcher = ChefLicensing::LicenseKeyFetcher::File.new({ dir: tmpdir })
        file_fetcher.persist("tmns-0f76efaf-e45e-4d92-86b2-2d144ce73dfa-150", "trial")
        file_fetcher.persist("tmns-0f76efaf-f45f-4d92-86b2-2d144ce73dfa-150", "trial")
        expect(file_fetcher.fetch).to eq(%w{tmns-0f76efaf-e45e-4d92-86b2-2d144ce73dfa-150 tmns-0f76efaf-f45f-4d92-86b2-2d144ce73dfa-150})
        expect(file_fetcher.persisted?).to eq(true)
      end
    end

    # TODO: Works on local but fails in CI pipeline
    it "warns if disk to write the file is not writable" do
      skip "Fails in CI works on local"
      Dir.mktmpdir do |tmpdir|
        non_writable_dir_path = File.join(tmpdir, "non_writable")
        Dir.mkdir(non_writable_dir_path, 0466)
        file_fetcher = ChefLicensing::LicenseKeyFetcher::File.new({ dir: non_writable_dir_path, logger: logger })
        expect(logger).to receive(:warn).once
        expect(logger).to receive(:debug).once
        file_fetcher.persist("tmns-0f76efaf-e45e-4d92-86b2-2d144ce73dfa-150", "trial")
      end
    end

    it "throws error if license type is not valid" do
      Dir.mktmpdir do |tmpdir|
        file_fetcher = ChefLicensing::LicenseKeyFetcher::File.new({ dir: tmpdir })
        expect { file_fetcher.persist("tmns-0f76efaf-e45e-4d92-86b2-2d144ce73dfa-150", "invalid-type") }.to raise_error(ChefLicensing::LicenseKeyFetcher::LicenseKeyNotPersistedError, /License type invalid-type is not a valid license type./)
        expect(file_fetcher.persisted?).to eq(false)
      end
    end
  end
end
