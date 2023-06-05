require "spec_helper"
require_relative "../lib/chef-licensing"
require "tmpdir"
require "Date" unless defined?(Date)
require_relative "../lib/chef-licensing/context"

RSpec.describe ChefLicensing::LicenseKeyFetcher do

  let(:output) { StringIO.new }
  let(:logger) { Logger.new(output) }
  let(:api_version) { 2 }

  let(:describe_api_data) { JSON.parse(File.read("spec/fixtures/api_response_data/valid_describe_api_response.json")) }
  let(:client_api_data) { JSON.parse(File.read("spec/fixtures/api_response_data/valid_client_api_response.json")) }

  before do
    ChefLicensing.configure do |config|
      config.chef_product_name = "inspec"
      config.chef_entitlement_id = "3ff52c37-e41f-4f6c-ad4d-365192205968"
      config.license_server_url = "http://globalhost-license-server/License"
      config.output = output
      config.logger = logger
    end
  end

  describe "fetch" do
    let(:argv)  { ["--chef-license-key=tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150"] }
    let(:env) { { "CHEF_LICENSE_KEY" => "free-c0832d2d-1111-1ec1-b1e5-011d182dc341-111" } }
    let(:argv_with_space) { ["--chef-license-key", "tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150"] }
    before do
      stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/listLicenses")
        .to_return(body: { data: [], status_code: 403 }.to_json,
                  headers: { content_type: "application/json" })
    end

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
        expect(license_key_fetcher.fetch).to eq(%w{tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150 free-c0832d2d-1111-1ec1-b1e5-011d182dc341-111})
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
        expect(license_key_fetcher.fetch).to eq(%w{tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150 free-c0832d2d-1111-1ec1-b1e5-011d182dc341-111})
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
        expect(license_key_fetcher.fetch).to eq(%w{tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150 free-c0832d2d-1111-1ec1-b1e5-011d182dc341-111})
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

    context "no license keys are passed via any means but using on-prem service" do

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

      before do
        ChefLicensing.configure do |config|
          config.is_local_license_service = nil
          config.license_server_url = "http://localhost-license-server/License"
        end
        stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/listLicenses")
          .to_return(body: { data: ["tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150"], status_code: 200 }.to_json,
          headers: { content_type: "application/json" })
        ChefLicensing::Context.current_context = nil
      end

      let(:license_key_fetcher) { ChefLicensing::LicenseKeyFetcher.new(opts) }

      it "returns key fetched using on-prem service" do
        expect(license_key_fetcher.fetch).to eq(["tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150"])
      end
    end
  end

  describe "fetch_and_persist" do
    let(:argv) { ["--chef-license-key=tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150"] }
    let(:env) { { "CHEF_LICENSE_KEY" => "free-c0832d2d-1111-1ec1-b1e5-011d182dc341-111" } }
    before do
      ChefLicensing.configure do |config|
        config.is_local_license_service = nil
      end
      stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/listLicenses")
        .to_return(body: { data: [], status_code: 403 }.to_json,
                  headers: { content_type: "application/json" })
      ChefLicensing::Context.current_context = nil
    end

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

    context "the license is set via the argument & environment; the file does not exist" do
      let(:opts) {
        {
          dir: Dir.mktmpdir,
          output: output,
          logger: logger,
          argv: argv,
          env: env,
        }
      }
      let(:license_keys) {
        %w{tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150 free-c0832d2d-1111-1ec1-b1e5-011d182dc341-111}
      }
      let(:license_key_fetcher) { described_class.new(opts) }
      before do
        stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/validate")
          .with(query: { licenseId: "tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150", version: api_version })
          .to_return(body: { data: true, message: "License Id is valid", status_code: 200 }.to_json,
                     headers: { content_type: "application/json" })
        stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/validate")
          .with(query: { licenseId: "free-c0832d2d-1111-1ec1-b1e5-011d182dc341-111", version: api_version })
          .to_return(body: { data: true, message: "License Id is valid", status_code: 200 }.to_json,
                  headers: { content_type: "application/json" })
        stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
          .with(query: { licenseId: "tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150", entitlementId: ChefLicensing::Config.chef_entitlement_id })
          .to_return(body: { data: client_api_data, status_code: 200 }.to_json,
                    headers: { content_type: "application/json" })
        stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
          .with(query: { licenseId: "free-c0832d2d-1111-1ec1-b1e5-011d182dc341-111", entitlementId: ChefLicensing::Config.chef_entitlement_id })
          .to_return(body: { data: client_api_data, status_code: 200 }.to_json,
                  headers: { content_type: "application/json" })
        stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
          .with(query: { licenseId: license_keys.join(","), entitlementId: ChefLicensing::Config.chef_entitlement_id })
          .to_return(body: { data: client_api_data, status_code: 200 }.to_json,
                     headers: { content_type: "application/json" })
        stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/desc")
          .with(query: { licenseId: "tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150", entitlementId: ChefLicensing::Config.chef_entitlement_id })
          .to_return(body: { data: describe_api_data, status_code: 200 }.to_json,
            headers: { content_type: "application/json" })

      end
      it "creates file, persist only trial and not free due to active trial restriction" do
        expect(license_key_fetcher.fetch_and_persist).to eq(["tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150"])
      end
    end

    context "the license is set via the argument & environment; and the file exists" do
      let(:license_keys) {
        %w{tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150 free-c0832d2d-1111-1ec1-b1e5-011d182dc341-111}
      }
      before do
        stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/validate")
          .with(query: { licenseId: "tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150", version: api_version })
          .to_return(body: { data: true, message: "License Id is valid", status_code: 200 }.to_json,
                     headers: { content_type: "application/json" })
        stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/validate")
          .with(query: { licenseId: "free-c0832d2d-1111-1ec1-b1e5-011d182dc341-111", version: api_version })
          .to_return(body: { data: true, message: "License Id is valid", status_code: 200 }.to_json,
                  headers: { content_type: "application/json" })
        stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
          .with(query: { licenseId: "tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150", entitlementId: ChefLicensing::Config.chef_entitlement_id })
          .to_return(body: { data: client_api_data, status_code: 200 }.to_json,
                  headers: { content_type: "application/json" })
        stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
          .with(query: { licenseId: "free-c0832d2d-1111-1ec1-b1e5-011d182dc341-111", entitlementId: ChefLicensing::Config.chef_entitlement_id })
          .to_return(body: { data: client_api_data, status_code: 200 }.to_json,
                  headers: { content_type: "application/json" })
        stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
          .with(query: { licenseId: license_keys.join(","), entitlementId: ChefLicensing::Config.chef_entitlement_id })
          .to_return(body: { data: client_api_data, status_code: 200 }.to_json,
                     headers: { content_type: "application/json" })
        stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/desc")
          .with(query: { licenseId: "tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150", entitlementId: ChefLicensing::Config.chef_entitlement_id })
          .to_return(body: { data: describe_api_data, status_code: 200 }.to_json,
            headers: { content_type: "application/json" })
      end

      Dir.mktmpdir do |tmpdir|
        let(:opts) {
          {
            logger: logger,
            argv: argv,
            env: env,
            output: output,
            dir: tmpdir,
          }
        }

        let(:license_key_fetcher) { described_class.new(opts) }
        it "returns only trial and not free due to active trial restriction" do
          expect(license_key_fetcher.fetch_and_persist).to eq(["tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150"])
        end
      end
    end

    context "multiple free licenses are restricted and can only add one free license in file" do
      let(:argv) { ["--chef-license-key=free-c0832d2d-1111-1ec1-b1e5-011d182dc341-112"] }

      let(:describe_api_data) {
        {
          "license" => [{
            "licenseKey" => "free-c0832d2d-1111-1ec1-b1e5-011d182dc341-112",
            "serialNumber" => "testing",
            "name" => "testing",
            "status" => "active",
            "start" => "2022-12-02",
            "end" => "2023-12-02",
            "licenseType" => "trial",
            "limits" => [
               {
                "testing" => "software",
                 "id" => "guid",
                 "amount" => 2,
                 "measure" => "nodes",
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
        stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/validate")
          .with(query: { licenseId: "free-c0832d2d-1111-1ec1-b1e5-011d182dc341-111", version: api_version })
          .to_return(body: { data: true, message: "License Id is valid", status_code: 200 }.to_json,
                  headers: { content_type: "application/json" })
        stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/validate")
          .with(query: { licenseId: "free-c0832d2d-1111-1ec1-b1e5-011d182dc341-112", version: api_version })
          .to_return(body: { data: true, message: "License Id is valid", status_code: 200 }.to_json,
                headers: { content_type: "application/json" })
        stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
          .with(query: { licenseId: "free-c0832d2d-1111-1ec1-b1e5-011d182dc341-111", entitlementId: ChefLicensing::Config.chef_entitlement_id })
          .to_return(body: { data: client_api_data, status_code: 200 }.to_json,
                  headers: { content_type: "application/json" })
        stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
          .with(query: { licenseId: "free-c0832d2d-1111-1ec1-b1e5-011d182dc341-112", entitlementId: ChefLicensing::Config.chef_entitlement_id })
          .to_return(body: { data: client_api_data, status_code: 200 }.to_json,
                headers: { content_type: "application/json" })
        stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/desc")
          .with(query: { licenseId: "free-c0832d2d-1111-1ec1-b1e5-011d182dc341-112", entitlementId: ChefLicensing::Config.chef_entitlement_id })
          .to_return(body: { data: describe_api_data, status_code: 200 }.to_json,
            headers: { content_type: "application/json" })
      end

      Dir.mktmpdir do |tmpdir|
        let(:opts) {
          {
            logger: logger,
            argv: argv,
            env: env,
            output: output,
            dir: tmpdir,
          }
        }

        let(:license_key_fetcher) { described_class.new(opts) }
        it "only adds one free license and returns it" do
          expect(license_key_fetcher.fetch_and_persist).to eq(%w{free-c0832d2d-1111-1ec1-b1e5-011d182dc341-112})
        end
      end
    end

    context "no license keys are passed via any means but using on-prem service" do
      let(:argv) { [] }
      let(:env) { {} }

      before do
        ChefLicensing.configure do |config|
          config.is_local_license_service = nil
          config.license_server_url = "http://localhost-license-server/License"
        end
        stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/listLicenses")
          .to_return(body: { data: ["tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150"], status_code: 200 }.to_json,
          headers: { content_type: "application/json" })
        stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
          .with(query: { licenseId: "tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150", entitlementId: ChefLicensing::Config.chef_entitlement_id })
          .to_return(body: { data: client_api_data, status_code: 200 }.to_json,
                headers: { content_type: "application/json" })
        ChefLicensing::Context.current_context = nil
      end

      Dir.mktmpdir do |tmpdir|
        let(:opts) {
          {
            logger: logger,
            argv: argv,
            env: env,
            output: output,
            dir: tmpdir,
          }
        }

        let(:license_key_fetcher) { described_class.new(opts) }
        it "adds one license returned by on-prem service" do
          expect(license_key_fetcher.fetch_and_persist).to eq(%w{tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150})
        end
      end
    end
  end

  describe "verify license keys format" do

    before do
      ChefLicensing.configure do |config|
        config.is_local_license_service = nil
      end
      stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/listLicenses")
        .to_return(body: { data: [], status_code: 403 }.to_json,
                  headers: { content_type: "application/json" })
      ChefLicensing::Context.current_context = nil
    end

    context "when the license key is not in the correct format of uuid" do
      let(:argv)  { ["--chef-license-key=tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-"] }
      let(:env) { {} }

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

      it "raises an error with the message" do
        expect { license_key_fetcher.fetch }.to raise_error(ChefLicensing::LicenseKeyFetcher::Base::InvalidLicenseKeyFormat, /Malformed License Key passed on command line - should be/)
      end
    end

    context "when the license key is not in the correct format of Serial number" do
      let(:argv)  { ["--chef-license-key=A8BC-1XS2-4F6F-BWG8-E0N45"] }
      let(:env) { {} }

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

      it "raises an error with the message" do
        expect { license_key_fetcher.fetch }.to raise_error(ChefLicensing::LicenseKeyFetcher::Base::InvalidLicenseKeyFormat, /Malformed License Key passed on command line - should be/)
      end
    end

    context "when the license key is in correct format of serial number but less than 26 characters" do
      let(:argv)  { ["--chef-license-key=A8BCD1XS2B4F6FYBWG8TE0N4"] }
      let(:env) { {} }

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

      it "raises an error with the message" do
        expect { license_key_fetcher.fetch }.to raise_error(ChefLicensing::LicenseKeyFetcher::Base::InvalidLicenseKeyFormat, /Malformed License Key passed on command line - should be/)
      end
    end

    context "when the license key is in the correct format of uuid" do
      let(:argv)  { ["--chef-license-key=tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150"] }
      let(:env) { {} }

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

      it "returns the license key" do
        expect(license_key_fetcher.fetch).to eq(["tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150"])
      end
    end

    context "when the license key is in the correct format of serial number" do
      let(:argv)  { ["--chef-license-key=A8BCD1XS2B4F6FYBWG8TE0N490"] }
      let(:env) { {} }

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

      it "returns the license key" do
        expect(license_key_fetcher.fetch).to eq(["A8BCD1XS2B4F6FYBWG8TE0N490"])
      end
    end

    context "when the license key is in the correct format of commercial license" do
      let(:argv)  { ["--chef-license-key=e0b8f317-7abd-1800-181b-ef2d5fc023d2"] }
      let(:env) { {} }

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

      it "returns the license key" do
        expect(license_key_fetcher.fetch).to eq(["e0b8f317-7abd-1800-181b-ef2d5fc023d2"])
      end
    end

    context "when the license key is in  incorrect format of commercial license" do
      let(:argv)  { ["--chef-license-key=hello-7abd-1800-181b-ef2d5fc023d2"] }
      let(:env) { {} }

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

      it "raises an error with the message" do
        expect { license_key_fetcher.fetch }.to raise_error(ChefLicensing::LicenseKeyFetcher::Base::InvalidLicenseKeyFormat, /Malformed License Key passed on command line - should be/)
      end
    end
  end

  describe "verify about to expire or expired licenses" do
    before do
      ChefLicensing.configure do |config|
        config.is_local_license_service = nil
      end
      stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/listLicenses")
        .to_return(body: { data: [], status_code: 403 }.to_json,
                  headers: { content_type: "application/json" })
      ChefLicensing::Context.current_context = nil
    end

    let(:argv) { ["--chef-license-key=tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150"] }
    let(:env) { {} }

    let(:license_keys) {
      %w{tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150}
    }

    context "when the license key is about to expire in 1 day within a week" do

      let(:client_data_about_to_expire_in_1_day) {
        {
          "client" => {
            "license" => "Trial",
            "status" => "Active",
            "changesTo" => "Expired",
            "changesOn" => "#{Date.today + 1}",
            "changesIn" => "1",
            "usage" => "Active",
            "used" => 2,
            "limit" => 2,
            "measure" => 2,
          },
          "assets" => [ { "id" => "assetguid1", "name" => "Test Asset 1" }, { "id" => "assetguid2", "name" => "Test Asset 2" } ],
          "features" => [ { "id" => "featureguid1", "name" => "Test Feature 1" }, { "id" => "featureguid2", "name" => "Test Feature 2" } ],
          "entitlement" => {
            "id" => "3ff52c37-e41f-4f6c-ad4d-365192205968",
            "name" => "Inspec",
            "start" => "2022-11-01",
            "end" => "2024-11-01",
            "licenses" => 2,
            "limits" => [ { "measure" => "nodes", "amount" => 2 } ],
            "entitled" => false,
          },
        }
      }

      Dir.mktmpdir do |tmpdir|
        let(:opts) {
          {
            logger: logger,
            argv: argv,
            env: env,
            output: output,
            dir: tmpdir,
          }
        }

        let(:license_key_fetcher) { described_class.new(opts) }
        before do
          stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/validate")
            .with(query: { licenseId: license_keys.first, version: api_version })
            .to_return(body: { data: true, message: "License Id is valid", status_code: 200 }.to_json,
                       headers: { content_type: "application/json" })
          stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
            .with(query: { licenseId: license_keys.join(","), entitlementId: ChefLicensing::Config.chef_entitlement_id })
            .to_return(body: { data: client_data_about_to_expire_in_1_day, status_code: 200 }.to_json,
                       headers: { content_type: "application/json" })
        end

        it "nags that it is about to expire" do
          license_key_fetcher.fetch_and_persist
          expect(license_key_fetcher.config[:start_interaction]).to eq(:prompt_license_about_to_expire)
        end
      end
    end

    context "when the license key is about to expire in 2 days within a week" do

      let(:client_data_about_to_expire_in_2_days) {
        {
          "client" => {
            "license" => "Trial",
            "status" => "Active",
            "changesTo" => "Expired",
            "changesOn" => "#{Date.today + 2}",
            "changesIn" => "2",
            "usage" => "Active",
            "used" => 2,
            "limit" => 2,
            "measure" => 2,
          },
          "assets" => [ { "id" => "assetguid1", "name" => "Test Asset 1" }, { "id" => "assetguid2", "name" => "Test Asset 2" } ],
          "features" => [ { "id" => "featureguid1", "name" => "Test Feature 1" }, { "id" => "featureguid2", "name" => "Test Feature 2" } ],
          "entitlement" => {
            "id" => "3ff52c37-e41f-4f6c-ad4d-365192205968",
            "name" => "Inspec",
            "start" => "2022-11-01",
            "end" => "2024-11-01",
            "licenses" => 2,
            "limits" => [ { "measure" => "nodes", "amount" => 2 } ],
            "entitled" => false,
          },
        }
      }

      Dir.mktmpdir do |tmpdir|
        let(:opts) {
          {
            logger: logger,
            argv: argv,
            env: env,
            output: output,
            dir: tmpdir,
          }
        }

        let(:license_key_fetcher) { described_class.new(opts) }
        before do
          stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/validate")
            .with(query: { licenseId: license_keys.first, version: api_version })
            .to_return(body: { data: true, message: "License Id is valid", status_code: 200 }.to_json,
                       headers: { content_type: "application/json" })
          stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
            .with(query: { licenseId: license_keys.join(","), entitlementId: ChefLicensing::Config.chef_entitlement_id })
            .to_return(body: { data: client_data_about_to_expire_in_2_days, status_code: 200 }.to_json,
                       headers: { content_type: "application/json" })
        end

        it "nags that it is about to expire" do
          license_key_fetcher.fetch_and_persist
          expect(license_key_fetcher.config[:start_interaction]).to eq(:prompt_license_about_to_expire)
        end
      end
    end

    context "when the license key is about to expire in 7 days within a week" do

      let(:client_data_about_to_expire_in_7_days) {
        {
          "client" => {
            "license" => "Trial",
            "status" => "Active",
            "changesTo" => "Expired",
            "changesOn" => "#{Date.today + 7}",
            "changesIn" => "7",
            "usage" => "Active",
            "used" => 2,
            "limit" => 2,
            "measure" => 2,
          },
          "assets" => [ { "id" => "assetguid1", "name" => "Test Asset 1" }, { "id" => "assetguid2", "name" => "Test Asset 2" } ],
          "features" => [ { "id" => "featureguid1", "name" => "Test Feature 1" }, { "id" => "featureguid2", "name" => "Test Feature 2" } ],
          "entitlement" => {
            "id" => "3ff52c37-e41f-4f6c-ad4d-365192205968",
            "name" => "Inspec",
            "start" => "2022-11-01",
            "end" => "2024-11-01",
            "licenses" => 2,
            "limits" => [ { "measure" => "nodes", "amount" => 2 } ],
            "entitled" => false,
          },
        }
      }

      Dir.mktmpdir do |tmpdir|
        let(:opts) {
          {
            logger: logger,
            argv: argv,
            env: env,
            output: output,
            dir: tmpdir,
          }
        }

        let(:license_key_fetcher) { described_class.new(opts) }
        before do
          stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/validate")
            .with(query: { licenseId: license_keys.first, version: api_version })
            .to_return(body: { data: true, message: "License Id is valid", status_code: 200 }.to_json,
                       headers: { content_type: "application/json" })
          stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
            .with(query: { licenseId: license_keys.join(","), entitlementId: ChefLicensing::Config.chef_entitlement_id })
            .to_return(body: { data: client_data_about_to_expire_in_7_days, status_code: 200 }.to_json,
                       headers: { content_type: "application/json" })
        end

        it "nags that it is about to expire" do
          license_key_fetcher.fetch_and_persist
          expect(license_key_fetcher.config[:start_interaction]).to eq(:prompt_license_about_to_expire)
        end
      end
    end

    context "when the license key is going to expire in 8 days, greater than a week threshold" do

      let(:client_data_about_to_expire_in_8_days) {
        {
          "client" => {
            "license" => "Trial",
            "status" => "Active",
            "changesTo" => "Expired",
            "changesOn" => "#{Date.today + 8}",
            "changesIn" => "8",
            "usage" => "Active",
            "used" => 2,
            "limit" => 2,
            "measure" => 2,
          },
          "assets" => [ { "id" => "assetguid1", "name" => "Test Asset 1" }, { "id" => "assetguid2", "name" => "Test Asset 2" } ],
          "features" => [ { "id" => "featureguid1", "name" => "Test Feature 1" }, { "id" => "featureguid2", "name" => "Test Feature 2" } ],
          "entitlement" => {
            "id" => "3ff52c37-e41f-4f6c-ad4d-365192205968",
            "name" => "Inspec",
            "start" => "2022-11-01",
            "end" => "2024-11-01",
            "licenses" => 2,
            "limits" => [ { "measure" => "nodes", "amount" => 2 } ],
            "entitled" => false,
          },
        }
      }

      Dir.mktmpdir do |tmpdir|
        let(:opts) {
          {
            logger: logger,
            argv: argv,
            env: env,
            output: output,
            dir: tmpdir,
          }
        }

        let(:license_key_fetcher) { described_class.new(opts) }
        before do
          stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/validate")
            .with(query: { licenseId: license_keys.first, version: api_version })
            .to_return(body: { data: true, message: "License Id is valid", status_code: 200 }.to_json,
                       headers: { content_type: "application/json" })
          stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
            .with(query: { licenseId: license_keys.join(","), entitlementId: ChefLicensing::Config.chef_entitlement_id })
            .to_return(body: { data: client_data_about_to_expire_in_8_days, status_code: 200 }.to_json,
                       headers: { content_type: "application/json" })
        end

        it "does not nags that it is about to expire" do
          license_key_fetcher.fetch_and_persist
          expect(license_key_fetcher.config[:start_interaction]).to eq(nil)
        end
      end
    end

    context "when the license key is expired and no day left, lesser than a min threshold of 1 day" do

      let(:client_data_expired) {
        {
          "client" => {
            "license" => "Trial",
            "status" => "Expired",
            "changesTo" => "Expired",
            "changesOn" => "#{Date.today}",
            "changesIn" => "0",
            "usage" => "Active",
            "used" => 2,
            "limit" => 2,
            "measure" => 2,
          },
          "assets" => [ { "id" => "assetguid1", "name" => "Test Asset 1" }, { "id" => "assetguid2", "name" => "Test Asset 2" } ],
          "features" => [ { "id" => "featureguid1", "name" => "Test Feature 1" }, { "id" => "featureguid2", "name" => "Test Feature 2" } ],
          "entitlement" => {
            "id" => "3ff52c37-e41f-4f6c-ad4d-365192205968",
            "name" => "Inspec",
            "start" => "2022-11-01",
            "end" => "2024-11-01",
            "licenses" => 2,
            "limits" => [ { "measure" => "nodes", "amount" => 2 } ],
            "entitled" => false,
          },
        }
      }

      Dir.mktmpdir do |tmpdir|
        let(:opts) {
          {
            logger: logger,
            argv: argv,
            env: env,
            output: output,
            dir: tmpdir,
          }
        }

        let(:license_key_fetcher) { described_class.new(opts) }
        before do
          stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/validate")
            .with(query: { licenseId: license_keys.first, version: api_version })
            .to_return(body: { data: true, message: "License Id is valid", status_code: 200 }.to_json,
                       headers: { content_type: "application/json" })
          stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
            .with(query: { licenseId: license_keys.join(","), entitlementId: ChefLicensing::Config.chef_entitlement_id })
            .to_return(body: { data: client_data_expired, status_code: 200 }.to_json,
                       headers: { content_type: "application/json" })
        end

        it "does not nags that it is about to expire but that it is expired" do
          license_key_fetcher.fetch_and_persist
          expect(license_key_fetcher.config[:start_interaction]).to_not eq(:prompt_license_about_to_expire)
          expect(license_key_fetcher.config[:start_interaction]).to_not eq(nil)
          expect(license_key_fetcher.config[:start_interaction]).to eq(:prompt_license_expired)
        end
      end
    end
  end
end