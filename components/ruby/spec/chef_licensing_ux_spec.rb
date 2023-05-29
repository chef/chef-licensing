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
  let(:valid_trial_license_key) { "tmns-58555821-925e-4a27-8fdc-e79dae5a425b-1234" }
  let(:valid_client_api_data) { JSON.parse(File.read("spec/fixtures/api_response_data/valid_client_api_response.json")) }
  let(:valid_describe_api_data) { JSON.parse(File.read("spec/fixtures/api_response_data/valid_describe_api_response.json")) }
  let(:valid_free_license_key) { "free-c0832d2d-1111-1ec1-b1e5-011d182dc341-111" }

  # escape sequences for arrow keys
  let(:simulate_up_arrow) { "\e[A" }
  let(:simulate_down_arrow) { "\e[B" }

  let(:user_details_payload) {
    {
      first_name: "John",
      last_name: "Doe",
      email_id: "johndoe@chef.com",
      product: "Inspec",
      company: "Progress Chef",
      phone: "123-456-7890",
    }
  }

  let(:free_license_generation_success_response) {
    {
      "delivery": "RealTime",
      "licenseId": valid_free_license_key,
      "message": "Success",
      "status_code": 200,
    }.to_json
  }

  let(:prompt) { TTY::Prompt::Test.new }

  let(:opts) {
    {
      prompt: prompt,
      interaction_file: interaction_file,
    }
  }

  before do
    ChefLicensing.configure do |config|
      config.logger = logger
      config.output = output
      config.license_server_url = "http://localhost-license-server/License"
      config.air_gap_status = false
      config.chef_product_name = "inspec"
      config.chef_entitlement_id = "3ff52c37-e41f-4f6c-ad4d-365192205968"
    end
  end

  before do
    stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/validate")
      .with(query: { licenseId: valid_free_license_key, version: 2 })
      .to_return(body: { data: true, message: "License Id is valid", status_code: 200 }.to_json,
                 headers: { content_type: "application/json" })

    stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
      .with(query: { licenseId: valid_free_license_key, entitlementId: ChefLicensing::Config.chef_entitlement_id })
      .to_return(body: { data: valid_client_api_data, status_code: 200 }.to_json,
                headers: { content_type: "application/json" })

    stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/desc")
      .with(query: { licenseId: valid_free_license_key, entitlementId: ChefLicensing::Config.chef_entitlement_id })
      .to_return(body: { data: valid_describe_api_data, status_code: 200 }.to_json,
                headers: { content_type: "application/json" })

    stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/validate")
      .with(query: { licenseId: valid_trial_license_key, version: 2 })
      .to_return(body: { data: true, message: "License Id is valid", status_code: 200 }.to_json,
                  headers: { content_type: "application/json" })

    stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
      .with(query: { licenseId: valid_trial_license_key, entitlementId: ChefLicensing::Config.chef_entitlement_id })
      .to_return(body: { data: valid_client_api_data, status_code: 200 }.to_json,
                headers: { content_type: "application/json" })

    stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/desc")
      .with(query: { licenseId: valid_trial_license_key, entitlementId: ChefLicensing::Config.chef_entitlement_id })
      .to_return(body: { data: valid_describe_api_data, status_code: 200 }.to_json,
                headers: { content_type: "application/json" })

    stub_request(:post, "#{ChefLicensing::Config.license_server_url}/v1/free")
      .with(body: user_details_payload.to_json)
      .to_return(body: free_license_generation_success_response,
                  headers: { content_type: "application/json" })
  end

  context "ux for tui entry - user enters a valid trial license id" do

    let(:start_interaction) { :start }

    # user press enters to select I already have a license ID
    # user enters a valid license key
    # user presses enter to continue
    before do
      prompt.input << "\n"
      prompt.input << valid_trial_license_key
      prompt.input << "\n"
      prompt.input.rewind
    end

    let(:tui_engine) { described_class.new(opts) }

    it "exits successfully traversing through the interactions in expected order" do
      expect { tui_engine.run_interaction(start_interaction) }.to_not raise_error
      expect(tui_engine.traversed_interaction).to eq(%i{start ask_if_user_has_license_id ask_for_license_id validate_license_id_pattern validate_license_id_with_api validate_license_restriction validation_success display_license_info fetch_license_id})
      expect(prompt.output.string).to include("I already have a license ID")
      expect(prompt.output.string).to include("Please enter your license ID:")
      expect(prompt.output.string).to include("License validated successfully")
    end
  end

  context "free license entry ux, user enters a valid and properly formatted free license" do
    let(:start_interaction) { :start }

    before do
      prompt.input << "\n"
      prompt.input << valid_free_license_key
      prompt.input << "\n"
      prompt.input.rewind
    end

    let(:tui_engine) { described_class.new(opts) }

    it "exits successfully traversing through the interactions in expected order" do
      expect { tui_engine.run_interaction(start_interaction) }.to_not raise_error
      expect(tui_engine.traversed_interaction).to eq(%i{start ask_if_user_has_license_id ask_for_license_id validate_license_id_pattern validate_license_id_with_api validate_license_restriction validation_success display_license_info fetch_license_id})
      expect(prompt.output.string).to include("I already have a license ID")
      expect(prompt.output.string).to include("Please enter your license ID:")
      expect(prompt.output.string).to include("License validated successfully")
    end
  end

  context "free license entry ux, user enters bad license followed by a valid and properly formatted license" do
    let(:start_interaction) { :start }

    before do
      prompt.input << "\n"
      prompt.input << "some-invalid-license-key"
      prompt.input << "\n"
      prompt.input << valid_free_license_key
      prompt.input << "\n"
      prompt.input.rewind
    end

    let(:tui_engine) { described_class.new(opts) }

    it "exits successfully traversing through the interactions in expected order" do
      expect { tui_engine.run_interaction(start_interaction) }.to_not raise_error
      expect(tui_engine.traversed_interaction).to eq(%i{start ask_if_user_has_license_id ask_for_license_id validate_license_id_pattern ask_for_license_id validate_license_id_pattern validate_license_id_with_api validate_license_restriction validation_success display_license_info fetch_license_id})
      expect(prompt.output.string).to include("I already have a license ID")
      expect(prompt.output.string).to include("Please enter your license ID:")
      expect(output.string).to include("Malformed License Key passed on command line - should be ")
      expect(prompt.output.string).to include("License validated successfully")
    end
  end

  context "free license generation ux, user follows all steps correctly" do
    let(:start_interaction) { :start }

    before do
      prompt.input << simulate_down_arrow
      prompt.input << "\n\n"
      prompt.input << "John\nDoe\njohndoe@chef.com\nProgress Chef\n123-456-7890\n"
      prompt.input << "\n"
      prompt.input << valid_free_license_key
      prompt.input << "\n"
      prompt.input.rewind
    end

    let(:tui_engine) { described_class.new(opts) }

    let(:expected_flow_for_license_generation) {
      %i{
        start
        ask_if_user_has_license_id
        info_of_license_types
        filter_license_type_options
        ask_for_all_license_type
        free_license_disclaimer
        free_license_selection
        check_if_user_details_are_present
        ask_for_user_details
        gather_user_first_name_for_license_generation
        validate_user_first_name_for_license_generation
        gather_user_last_name_for_license_generation
        validate_user_last_name_for_license_generation
        gather_user_email_for_license_generation
        validate_user_email_for_license_generation
        gather_user_company_for_license_generation
        validate_user_company_name_for_license_generation
        gather_user_phone_no_for_license_generation
        validate_user_phone_no
        print_to_review_details
        ask_for_review_confirmation
        pre_license_generation
        generate_free_license
        free_license_generation_success
        ask_for_license_id
        validate_license_id_pattern
        validate_license_id_with_api
        validate_license_restriction
        validation_success
        display_license_info
        fetch_license_id
      }
    }

    it "generates the license successfully traversing through the interactions in expected order" do
      expect { tui_engine.run_interaction(start_interaction) }.to_not raise_error
      expect(tui_engine.traversed_interaction).to eq(expected_flow_for_license_generation)
      expect(prompt.output.string).to include("I don't have a license ID and would like to generate a new license ID")
      expect(prompt.output.string).to include("Select the type of license below and then enter user details")
      expect(prompt.output.string).to include("A Free License can be used for personal, non-commercial use only.")
      expect(prompt.output.string).to include("Please enter the following details:\nFirst Name, Last Name, Email, Company, Phone")
      expect(prompt.output.string).to include("The license ID has been sent to johndoe@chef.com")
    end
  end
end