require "spec_helper"
require_relative "../lib/chef_licensing/config"
require "tmpdir"

RSpec.describe ChefLicensing::LicenseKeyFetcher do

  let(:env_opts) {
    {
      env_vars: {
        "CHEF_LICENSE_SERVER" => "http://localhost-license-server/License",
        "CHEF_LICENSE_SERVER_API_KEY" =>  "xDblv65Xt84wULmc8qTN78a3Dr2OuuKxa6GDvb67",
        "CHEF_PRODUCT_NAME" => "inspec",
        "CHEF_ENTITLEMENT_ID" => "3ff52c37-e41f-4f6c-ad4d-365192205968",
      },
    }
  }

  let(:config) {
    ChefLicensing::Config.clone.instance(env_opts)
  }

  describe "fetch" do
    let(:output) { StringIO.new }
    let(:logger) { Logger.new(output) }
    let(:argv)  { ["--chef-license-key=tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150"] }
    let(:env) { { "CHEF_LICENSE_KEY" => "tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-152" } }

    context "the license keys are passed in via the CLI and ENV; & file doesn't exist" do
      let(:opts) {
        {
          logger: logger,
          argv: argv,
          env: env,
          output: output,
          dir: nil,
          cl_config: config,
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
          cl_config: config,
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
          cl_config: config,
        }
      }

      let(:license_key_fetcher) { ChefLicensing::LicenseKeyFetcher.new(opts) }

      it "returns an empty array" do
        expect(license_key_fetcher.fetch).to eq([])
      end
    end
  end

  describe "fetch_and_persist" do
    let(:output) { StringIO.new }
    let(:logger) { Logger.new(output) }
    let(:argv) { ["--chef-license-key=tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150"] }
    let(:env) { { "CHEF_LICENSE_KEY" => "tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-152" } }

    let(:api_version) {
      2

    let(:client_data) {
      {
        "cache": {
          "lastModified": "2023-01-16T12:05:40Z",
          "evaluatedOn": "2023-01-16T12:07:20.114370692Z",
          "expires": "2023-01-17T12:07:20.114370783Z",
          "cacheControl": "private,max-age:42460",
        },
        "client" => {
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

    context "the file does not exist; and no license keys are set either via arg or env" do
      let(:opts) {
        {
          output: output,
          logger: logger,
          cl_config: config,
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
          cl_config: config,
        }
      }
      let(:license_keys) {
        %w{tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150 tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-152}
      }
      let(:license_key_fetcher) { described_class.new(opts) }
      before do
        stub_request(:get, "#{config.license_server_url}/v1/validate")
          .with(query: { licenseId: "tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150", version: api_version })
          .to_return(body: { data: true, message: "License Id is valid", status_code: 200 }.to_json,
                     headers: { content_type: "application/json" })
        stub_request(:get, "#{config.license_server_url}/v1/validate")
        .with(query: { licenseId: "tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-152", version: api_version })
        .to_return(body: { data: true, message: "License Id is valid", status_code: 200 }.to_json,
                  headers: { content_type: "application/json" })
        stub_request(:get, "#{config.license_server_url}/client")
          .with(query: { licenseId: license_keys.join(","), entitlementId: config.chef_entitlement_id })
          .to_return(body: { data: client_data, status_code: 200 }.to_json,
                     headers: { content_type: "application/json" })
      end
      it "creates file, persist both license keys in the file, returns them all" do
        expect(license_key_fetcher.fetch_and_persist).to eq(%w{tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150 tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-152})
      end
    end

    context "the license is set via the argument & environment; and the file exists" do
      let(:license_keys) {
        %w{tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150 tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-152}
      }
      before do
        stub_request(:get, "#{config.license_server_url}/v1/validate")
          .with(query: { licenseId: "tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150", version: api_version })
          .to_return(body: { data: true, message: "License Id is valid", status_code: 200 }.to_json,
                     headers: { content_type: "application/json" })
        stub_request(:get, "#{config.license_server_url}/v1/validate")
        .with(query: { licenseId: "tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-152", version: api_version })
        .to_return(body: { data: true, message: "License Id is valid", status_code: 200 }.to_json,
                  headers: { content_type: "application/json" })
        stub_request(:get, "#{config.license_server_url}/client")
          .with(query: { licenseId: license_keys.join(","), entitlementId: config.chef_entitlement_id })
          .to_return(body: { data: client_data, status_code: 200 }.to_json,
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
            cl_config: config,
          }
        }

        let(:license_key_fetcher) { described_class.new(opts) }
        it "returns all the license keys" do
          expect(license_key_fetcher.fetch_and_persist).to eq(%w{tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150 tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-152})
        end
      end
    end
  end
end
