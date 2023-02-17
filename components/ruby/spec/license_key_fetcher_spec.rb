require "spec_helper"
require_relative "../lib/chef_licensing"
require "tmpdir"

RSpec.describe ChefLicensing::LicenseKeyFetcher do

  let(:output) { StringIO.new }
  let(:logger) { Logger.new(output) }

  before do
    ChefLicensing.configure do |config|
      config.chef_product_name = "inspec"
      config.chef_entitlement_id = "3ff52c37-e41f-4f6c-ad4d-365192205968"
      config.license_server_url = "http://localhost-license-server/License"
      config.license_server_api_key = "xDblv65Xt84wULmc8qTN78a3Dr2OuuKxa6GDvb67"
      config.output = output
      config.logger = logger
    end
  end

  describe "fetch" do
    let(:argv)  { ["--chef-license-key=tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150"] }
    let(:env) { { "CHEF_LICENSE_KEY" => "tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-152" } }
    let(:argv_with_space) { ["--chef-license-key", "tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150"] }

    context "the license keys are passed in via the CLI with space and ENV; & file doesn't exist" do
      let(:opts) {
        {
          logger: logger,
          argv: argv_with_space,
          env: env,
          output: output,
          dir: nil,
        }
      }

      let(:license_key_fetcher) { ChefLicensing::LicenseKeyFetcher.new(opts) }

      it "returns both license keys" do
        expect(license_key_fetcher.fetch).to eq(%w{tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150 tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-152})
      end
    end

    context "the license keys are passed in via the CLI and ENV; & file doesn't exist" do
      let(:opts) {
        {
          logger: logger,
          argv: argv,
          env: env,
          output: output,
          dir: nil,
        }
      }

      let(:license_key_fetcher) { ChefLicensing::LicenseKeyFetcher.new(opts) }

      it "returns both license keys" do
        expect(license_key_fetcher.fetch).to eq(%w{tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150 tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-152})
      end
    end

    context "the license keys are passed in via the CLI and ENV; & file exists with a valid license" do
      let(:multiple_keys_license_dir) { "spec/fixtures/multiple_license_keys_license" }

      let(:opts) {
        {
          logger: logger,
          argv: argv,
          env: env,
          output: output,
          dir: multiple_keys_license_dir,
        }
      }

      let(:license_key_fetcher) { ChefLicensing::LicenseKeyFetcher.new(opts) }

      it "returns all unique license keys" do
        expect(license_key_fetcher.fetch).to eq(%w{tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150 tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-152 tmns-0f76efaf-c45c-4d92-86b2-2d144ce73dfa-150})
      end
    end

    context "no license keys are passed via any means" do
      let(:argv) { [] }
      let(:env) { {} }

      let(:opts) {
        {
          logger: logger,
          output: output,
          argv: argv,
          env: env,
          dir: nil,
        }
      }

      let(:license_key_fetcher) { ChefLicensing::LicenseKeyFetcher.new(opts) }

      it "returns an empty array" do
        expect(license_key_fetcher.fetch).to eq([])
      end
    end
  end

  describe "fetch_and_persist" do
    let(:argv) { ["--chef-license-key=tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150"] }
    let(:env) { { "CHEF_LICENSE_KEY" => "tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-152" } }

    let(:api_version) {
      2
    }

    context "the file does not exist; and no license keys are set either via arg or env" do
      let(:opts) {
        {
          output: output,
          logger: logger,
        }
      }
      let(:license_key_fetcher) { described_class.new(opts) }
      it "raises an error" do
        expect { license_key_fetcher.fetch_and_persist }.to raise_error(ChefLicensing::LicenseKeyFetcher::LicenseKeyNotFetchedError)
      end
    end

    context "the license is set via the argument and is getting validated" do
      let(:license_key) {
        "tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150"
      }
      before do
        stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/validate")
          .with(query: { licenseId: license_key, version: api_version })
          .to_return(body: { data: true, message: "License Id is valid", status_code: 200 }.to_json,
                     headers: { content_type: "application/json" })
      end
      Dir.mktmpdir do |tmpdir|
        let(:opts) {
          {
            dir: tmpdir,
            output: output,
            logger: logger,
            argv: argv,
          }
        }
        let(:license_key_fetcher) { described_class.new(opts) }
        it "creates file, persist both license keys in the file, returns them all" do
          expect(license_key_fetcher.fetch_and_persist).to eq(%w{tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150})
        end
      end
    end

    context "the license is set via the environment and is getting validated" do
      let(:license_key) {
        "tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-152"
      }
      before do
        stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/validate")
          .with(query: { licenseId: license_key, version: api_version })
          .to_return(body: { data: true, message: "License Id is valid", status_code: 200 }.to_json,
                     headers: { content_type: "application/json" })
      end
      Dir.mktmpdir do |tmpdir|
        let(:opts) {
          {
            dir: tmpdir,
            output: output,
            logger: logger,
            env: env,
          }
        }
        let(:license_key_fetcher) { described_class.new(opts) }
        it "creates file, persist both license keys in the file, returns them all" do
          expect(license_key_fetcher.fetch_and_persist).to eq(%w{tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-152})
        end
      end
    end
  end
end
