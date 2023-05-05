require "chef-licensing/tui_engine/tui_engine"
require "chef-licensing/config"
require "spec_helper"
require "stringio"
require "chef-licensing"
require "tty-prompt"
require "tty/prompt/test"
require "json"

RSpec.describe ChefLicensing::TUIEngine do
  let(:interaction_file) { File.join("lib/chef-licensing/license_key_fetcher", "chef_licensing_interactions.yaml") }
  let(:output) { StringIO.new }
  let(:logger) { Logger.new(output) }
  let(:license_key) { "tmns-58555821-925e-4a27-8fdc-e79dae5a425b-1234" }
  let(:valid_client_api_data) { JSON.parse(File.read("spec/fixtures/api_response_data/valid_client_api_response.json")) }
  let(:valid_describe_api_data) { JSON.parse(File.read("spec/fixtures/api_response_data/valid_describe_api_response.json")) }

  before do
    ChefLicensing.configure do |config|
      config.logger = logger
      config.output = output
      config.license_server_url = "http://localhost-license-server/License"
      config.license_server_api_key = "xDblv65Xt84wULmc8qTN78a3Dr2OuuKxa6GDvb67"
      config.air_gap_status = false
      config.chef_product_name = "inspec"
      config.chef_entitlement_id = "3ff52c37-e41f-4f6c-ad4d-365192205968"
    end
  end

  context "ux for tui entry - user enters a valid license id" do
    subject(:prompt) { TTY::Prompt::Test.new }

    let(:opts) {
      {
        prompt: prompt,
        interaction_file: interaction_file,
      }
    }

    let(:start_interaction) { :start }

    # user press enters to select I already have a license ID
    # user enters a valid license key
    # user presses enter to continue
    before do
      prompt.input << "\n"
      prompt.input << "tmns-58555821-925e-4a27-8fdc-e79dae5a425b-1234"
      prompt.input << "\n"
      prompt.input.rewind
    end

    before do
      stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/validate")
        .with(query: { licenseId: license_key, version: 2 })
        .to_return(body: { data: true, message: "License Id is valid", status_code: 200 }.to_json,
                   headers: { content_type: "application/json" })

      stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
        .with(query: { licenseId: license_key, entitlementId: ChefLicensing::Config.chef_entitlement_id })
        .to_return(body: { data: valid_client_api_data, status_code: 200 }.to_json,
                  headers: { content_type: "application/json" })

      stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/desc")
        .with(query: { licenseId: license_key, entitlementId: ChefLicensing::Config.chef_entitlement_id })
        .to_return(body: { data: valid_describe_api_data, status_code: 200 }.to_json,
                  headers: { content_type: "application/json" })
    end

    let(:tui_engine) { described_class.new(opts) }

    it "exits successfully traversing through the interactions in expected order" do
      expect { tui_engine.run_interaction(start_interaction) }.to_not raise_error
      expect(tui_engine.traversed_interaction).to eq(%i{start ask_if_user_has_license_id ask_for_license_id validate_license_id_pattern validate_license_id_with_api validate_license_restriction validation_success display_license_info fetch_license_id})
      expect(prompt.output.string).to include("I already have a license ID")
      expect(prompt.output.string).to include("Please enter your License ID:")
      expect(prompt.output.string).to include("License validated successfully")
    end
  end
end