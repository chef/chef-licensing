require "chef-licensing/tui_engine/tui_engine"
require "chef-licensing/config"
require "spec_helper"
require "stringio"
require "chef-licensing"
require "tty-prompt"
require "tty/prompt/test"
require "json"
require "chef-licensing/license_key_fetcher"

RSpec.describe ChefLicensing::TUIEngine do
  let(:interaction_file) { File.join("lib/chef-licensing/license_key_fetcher", "chef_licensing_interactions.yaml") }
  let(:output) { StringIO.new }
  let(:logger) { Logger.new(output) }
  let(:valid_trial_license_key) { "tmns-58555821-925e-4a27-8fdc-e79dae5a425b-1234" }
  let(:valid_trial_license_key_2) { "tmns-58555821-925e-4a27-8fdc-e79dae5a425b-1235" }
  let(:expired_trial_license_key) { "tmns-58555821-925e-4a27-8fdc-e79dae5a425b-1236" }
  let(:valid_client_api_data) { JSON.parse(File.read("spec/fixtures/api_response_data/valid_client_api_response.json")) }
  let(:expired_trial_license_client_api_data) { JSON.parse(File.read("spec/fixtures/api_response_data/expired_trial_license_client_api_response.json")) }
  let(:valid_client_api_data_free_license) { JSON.parse(File.read("spec/fixtures/api_response_data/valid_client_api_response_free_license.json")) }
  let(:valid_describe_api_data) { JSON.parse(File.read("spec/fixtures/api_response_data/valid_describe_api_response.json")) }
  let(:valid_free_license_key) { "free-c0832d2d-1111-1ec1-b1e5-011d182dc341-111" }
  let(:valid_free_license_key_2) { "free-c0832d2d-1111-1ec1-b1e5-011d182dc341-112" }
  let(:exhausted_commercial_license) { "HA0D5BABCDEFG7X2E8SXYZ4MV4" }
  let(:exhausted_commercial_client_api_data) { JSON.parse(File.read("spec/fixtures/api_response_data/exhausted_commercial_client_api_response.json")) }
  let(:exhausted_free_license) { "free-11eef3a8-1234-4b4c-567d-dd8c1234567d-890" }
  let(:exhausted_free_client_api_data) { JSON.parse(File.read("spec/fixtures/api_response_data/exhausted_free_client_api_response.json")) }

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

  let(:additional_info_for_tui_engine) {
    {
      chef_product_name: ChefLicensing::Config.chef_product_name&.capitalize,
      unit_measure: "targets",
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

  let(:trial_license_generation_success_response) {
    {
      "delivery": "RealTime",
      "licenseId": valid_trial_license_key,
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
      config.license_server_url = "http://globalhost-license-server/License"
      config.license_server_url_check_in_file = true
      config.chef_product_name = "inspec"
      config.chef_entitlement_id = "3ff52c37-e41f-4f6c-ad4d-365192205968"
    end
  end

  # Stubbing all the required API calls
  before do
    stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/listLicenses")
      .to_return(body: { data: [], status_code: 404 }.to_json,
                  headers: { content_type: "application/json" })

    stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/validate")
      .with(query: { licenseId: valid_free_license_key, version: 2 })
      .to_return(body: { data: true, message: "License Id is valid", status_code: 200 }.to_json,
                 headers: { content_type: "application/json" })

    stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
      .with(query: { licenseId: valid_free_license_key, entitlementId: ChefLicensing::Config.chef_entitlement_id })
      .to_return(body: { data: valid_client_api_data_free_license, status_code: 200 }.to_json,
                headers: { content_type: "application/json" })

    stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/desc")
      .with(query: { licenseId: valid_free_license_key, entitlementId: ChefLicensing::Config.chef_entitlement_id })
      .to_return(body: { data: valid_describe_api_data, status_code: 200 }.to_json,
                headers: { content_type: "application/json" })

    stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/validate")
      .with(query: { licenseId: valid_free_license_key_2, version: 2 })
      .to_return(body: { data: true, message: "License Id is valid", status_code: 200 }.to_json,
                 headers: { content_type: "application/json" })

    stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
      .with(query: { licenseId: valid_free_license_key_2, entitlementId: ChefLicensing::Config.chef_entitlement_id })
      .to_return(body: { data: valid_client_api_data_free_license, status_code: 200 }.to_json,
                headers: { content_type: "application/json" })

    stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/desc")
      .with(query: { licenseId: valid_free_license_key_2, entitlementId: ChefLicensing::Config.chef_entitlement_id })
      .to_return(body: { data: valid_describe_api_data, status_code: 200 }.to_json,
                headers: { content_type: "application/json" })

    stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/validate")
      .with(query: { licenseId: valid_trial_license_key, version: 2 })
      .to_return(body: { data: true, message: "License Id is valid", status_code: 200 }.to_json,
                  headers: { content_type: "application/json" })

    stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/validate")
      .with(query: { licenseId: valid_trial_license_key_2, version: 2 })
      .to_return(body: { data: true, message: "License Id is valid", status_code: 200 }.to_json,
                  headers: { content_type: "application/json" })

    stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/validate")
      .with(query: { licenseId: expired_trial_license_key, version: 2 })
      .to_return(body: { data: true, message: "License Id is valid", status_code: 200 }.to_json,
                  headers: { content_type: "application/json" })

    stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
      .with(query: { licenseId: valid_trial_license_key, entitlementId: ChefLicensing::Config.chef_entitlement_id })
      .to_return(body: { data: valid_client_api_data, status_code: 200 }.to_json,
                headers: { content_type: "application/json" })

    stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
      .with(query: { licenseId: valid_trial_license_key_2, entitlementId: ChefLicensing::Config.chef_entitlement_id })
      .to_return(body: { data: valid_client_api_data, status_code: 200 }.to_json,
                headers: { content_type: "application/json" })

    stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
      .with(query: { licenseId: expired_trial_license_key, entitlementId: ChefLicensing::Config.chef_entitlement_id })
      .to_return(body: { data: expired_trial_license_client_api_data, status_code: 200 }.to_json,
                headers: { content_type: "application/json" })

    stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/desc")
      .with(query: { licenseId: valid_trial_license_key, entitlementId: ChefLicensing::Config.chef_entitlement_id })
      .to_return(body: { data: valid_describe_api_data, status_code: 200 }.to_json,
                headers: { content_type: "application/json" })

    stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/desc")
      .with(query: { licenseId: expired_trial_license_key, entitlementId: ChefLicensing::Config.chef_entitlement_id })
      .to_return(body: { data: valid_describe_api_data, status_code: 200 }.to_json,
                headers: { content_type: "application/json" })
    stub_request(:post, "#{ChefLicensing::Config.license_server_url}/v1/free")
      .with(body: user_details_payload.to_json)
      .to_return(body: free_license_generation_success_response,
                  headers: { content_type: "application/json" })

    stub_request(:post, "#{ChefLicensing::Config.license_server_url}/v1/trial")
      .with(body: user_details_payload.to_json)
      .to_return(body: trial_license_generation_success_response,
                headers: { content_type: "application/json" })

    stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/validate")
      .with(query: { licenseId: exhausted_commercial_license, version: 2 })
      .to_return(body: { data: true, message: "License Id is valid", status_code: 200 }.to_json,
                  headers: { content_type: "application/json" })

    stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
      .with(query: { licenseId: exhausted_commercial_license, entitlementId: ChefLicensing::Config.chef_entitlement_id })
      .to_return(body: { data: exhausted_commercial_client_api_data, status_code: 200 }.to_json,
                  headers: { content_type: "application/json" })

    stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/validate")
      .with(query: { licenseId: exhausted_free_license, version: 2 })
      .to_return(body: { data: true, message: "License Id is valid", status_code: 200 }.to_json,
                headers: { content_type: "application/json" })

    stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
      .with(query: { licenseId: exhausted_free_license, entitlementId: ChefLicensing::Config.chef_entitlement_id })
      .to_return(body: { data: exhausted_free_client_api_data, status_code: 200 }.to_json,
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
      expect(tui_engine.traversed_interaction).to eq(%i{start ask_if_user_has_license_id ask_for_license_id validate_license_id_pattern validate_license_id_with_api validate_license_restriction validate_license_expiration validation_success display_license_info fetch_license_id})
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
      expect(tui_engine.traversed_interaction).to eq(%i{start ask_if_user_has_license_id ask_for_license_id validate_license_id_pattern validate_license_id_with_api validate_license_restriction validate_license_expiration validation_success display_license_info fetch_license_id})
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
      expect(tui_engine.traversed_interaction).to eq(%i{start ask_if_user_has_license_id ask_for_license_id validate_license_id_pattern ask_for_license_id validate_license_id_pattern validate_license_id_with_api validate_license_restriction validate_license_expiration validation_success display_license_info fetch_license_id})
      expect(prompt.output.string).to include("I already have a license ID")
      expect(prompt.output.string).to include("Please enter your license ID:")
      expect(output.string).to include("Malformed License Key passed on command line - should be ")
      expect(prompt.output.string).to include("License validated successfully")
    end
  end

  context "free license generation ux, user follows all steps correctly and exits" do
    let(:start_interaction) { :start }

    before do
      prompt.input << simulate_down_arrow
      prompt.input << "\n\n"
      prompt.input << simulate_down_arrow
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
        free_trial_license_selection
        validate_license_later_message
      }
    }

    it "generates the license successfully traversing through the interactions in expected order" do
      expect { tui_engine.append_info_to_input(additional_info_for_tui_engine) }.to_not raise_error
      expect { tui_engine.run_interaction(start_interaction) }.to_not raise_error
      expect(tui_engine.traversed_interaction).to eq(expected_flow_for_license_generation)
      expect(prompt.output.string).to include("I don't have a license ID and would like to generate a new license ID")
      expect(prompt.output.string).to include("Select the type of license below and then enter user details")
      expect(prompt.output.string).to include("Quit and validate license later")
      expect(prompt.output.string).to include("You can enter the license later on by selecting")
      expect(prompt.output.string).to include("To learn about more ways to enter the license, kindly visit")
    end
  end

  context "free license generation ux, user follows all steps correctly and provides free license key; post generation from web" do
    let(:start_interaction) { :start }

    before do
      prompt.input << simulate_down_arrow
      prompt.input << "\n\n\n"
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
        free_trial_license_selection
        ask_for_license_id
        validate_license_id_pattern
        validate_license_id_with_api
        validate_license_restriction
        validate_license_expiration
        validation_success
        display_license_info
        fetch_license_id
      }
    }

    it "generates the license successfully traversing through the interactions in expected order" do
      expect { tui_engine.append_info_to_input(additional_info_for_tui_engine) }.to_not raise_error
      expect { tui_engine.run_interaction(start_interaction) }.to_not raise_error
      expect(tui_engine.traversed_interaction).to eq(expected_flow_for_license_generation)
      expect(prompt.output.string).to include("I don't have a license ID and would like to generate a new license ID")
      expect(prompt.output.string).to include("Select the type of license below and then enter user details")
      expect(prompt.output.string).to include("Kindly complete the user registration at")
      expect(prompt.output.string).to include("Once you submit the details, you will receive the license ID on the email id you provided.")
      expect(prompt.output.string).to include("Validate license now")
    end
  end

  context "free license restriction ux, user has a free license and tries to add another free license via tui" do
    Dir.mktmpdir do |tmpdir|
      let(:argv) { ["--chef-license-key=free-c0832d2d-1111-1ec1-b1e5-011d182dc341-111"] }

      let(:lkf_opts) {
        {
          argv: argv,
          dir: tmpdir,
        }
      }

      let(:license_key_fetcher) { ChefLicensing::LicenseKeyFetcher.new(lkf_opts) }

      let(:start_interaction) { :add_license_all }
      let(:opts) {
        {
          prompt: prompt,
          interaction_file: interaction_file,
          dir: tmpdir,
        }
      }
      let(:tui_engine) { described_class.new(opts) }

      before do
        ChefLicensing.configure do |config|
          config.is_local_license_service = nil
        end
        ChefLicensing::Context.current_context = nil
        license_key_fetcher.fetch_and_persist
      end

      it "checks if the license is persister" do
        expect(license_key_fetcher.fetch).to eq(["free-c0832d2d-1111-1ec1-b1e5-011d182dc341-111"])
      end

      before do
        prompt.input << "\n"
        prompt.input << valid_free_license_key_2
        prompt.input << "\n"
        prompt.input.rewind
        ChefLicensing::Context.current_context = nil
      end

      let(:expected_flow_for_license_restriction) {
        %i{
          add_license_all
          ask_if_user_has_license_id_for_license_addition
          ask_for_license_id
          validate_license_id_pattern
          validate_license_id_with_api
          validate_license_restriction
          prompt_error_license_addition_restricted
          license_restriction_header_text
          free_license_already_exist_message
          add_license_info_in_restriction_flow
          license_restriction_foot_text
          free_restriction_message
          exit_with_message
        }
      }

      it "doesn't allow to add another free license key" do
        expect { tui_engine.run_interaction(start_interaction) }.to_not raise_error
        expect(tui_engine.traversed_interaction).to eq(expected_flow_for_license_restriction)
        expect(prompt.output.string).to include("✖ [Error] License validation failed")
        expect(prompt.output.string).to include("A Free Tier License already exists with following details:")
        expect(prompt.output.string).to include("Please generate a Trial or Commercial License by running")
      end

    end

  end

  context "free license restriction ux, user has an active trail license and tries to add free license via tui" do
    Dir.mktmpdir do |tmpdir|
      let(:argv) { ["--chef-license-key=tmns-58555821-925e-4a27-8fdc-e79dae5a425b-1234"] }

      let(:lkf_opts) {
        {
          argv: argv,
          dir: tmpdir,
        }
      }

      let(:license_key_fetcher) { ChefLicensing::LicenseKeyFetcher.new(lkf_opts) }

      let(:start_interaction) { :add_license_all }
      let(:opts) {
        {
          prompt: prompt,
          interaction_file: interaction_file,
          dir: tmpdir,
        }
      }
      let(:tui_engine) { described_class.new(opts) }

      before do
        license_key_fetcher.fetch_and_persist
      end

      it "checks if the license is persisted" do
        expect(license_key_fetcher.fetch).to eq(["tmns-58555821-925e-4a27-8fdc-e79dae5a425b-1234"])
      end

      before do
        prompt.input << "\n"
        prompt.input << valid_free_license_key_2
        prompt.input << "\n"
        prompt.input.rewind
      end

      let(:expected_flow_for_license_restriction) {
        %i{
          add_license_all
          ask_if_user_has_license_id_for_license_addition
          ask_for_license_id
          validate_license_id_pattern
          validate_license_id_with_api
          validate_license_restriction
          prompt_error_license_addition_restricted
          license_restriction_header_text
          active_trial_exist_message
          add_license_info_in_restriction_flow
          license_restriction_foot_text
          only_commercial_allowed_message
          exit_with_message
        }
      }

      it "doesn't allow to add another free license key" do
        expect { tui_engine.run_interaction(start_interaction) }.to_not raise_error
        expect(tui_engine.traversed_interaction).to eq(expected_flow_for_license_restriction)
        expect(prompt.output.string).to include("✖ [Error] License validation failed")
        expect(prompt.output.string).to include("An active Trial License already exists with following details")
        expect(prompt.output.string).to include("Please generate a Commercial License by running")
      end
    end
  end

  context "trial license generation ux, user follows all steps correctly and exits" do
    let(:start_interaction) { :start }

    before do
      prompt.input << simulate_down_arrow
      prompt.input << "\n"
      prompt.input << simulate_down_arrow
      prompt.input << "\n"
      prompt.input << simulate_down_arrow
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
        free_trial_license_selection
        validate_license_later_message
      }
    }

    it "generates the license successfully traversing through the interactions in expected order" do
      expect { tui_engine.append_info_to_input(additional_info_for_tui_engine) }.to_not raise_error
      expect { tui_engine.run_interaction(start_interaction) }.to_not raise_error
      expect(tui_engine.traversed_interaction).to eq(expected_flow_for_license_generation)
      expect(prompt.output.string).to include("I don't have a license ID and would like to generate a new license ID")
      expect(prompt.output.string).to include("Select the type of license below and then enter user details")
      expect(prompt.output.string).to include("2. Trial License")
      expect(prompt.output.string).to include("No. of units: Unlimited targets")
      expect(prompt.output.string).to include("Quit and validate license later")
      expect(prompt.output.string).to include("You can enter the license later on by selecting")
      expect(prompt.output.string).to include("To learn about more ways to enter the license, kindly visit")
    end
  end

  context "trial license generation ux, user follows all steps correctly and provides a trial license; post generation from web" do
    let(:start_interaction) { :start }

    before do
      prompt.input << simulate_down_arrow
      prompt.input << "\n"
      prompt.input << simulate_down_arrow
      prompt.input << "\n\n"
      prompt.input << valid_trial_license_key
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
        free_trial_license_selection
        ask_for_license_id
        validate_license_id_pattern
        validate_license_id_with_api
        validate_license_restriction
        validate_license_expiration
        validation_success
        display_license_info
        fetch_license_id
      }
    }

    it "generates the license successfully traversing through the interactions in expected order" do
      expect { tui_engine.append_info_to_input(additional_info_for_tui_engine) }.to_not raise_error
      expect { tui_engine.run_interaction(start_interaction) }.to_not raise_error
      expect(tui_engine.traversed_interaction).to eq(expected_flow_for_license_generation)
      expect(prompt.output.string).to include("I don't have a license ID and would like to generate a new license ID")
      expect(prompt.output.string).to include("Select the type of license below and then enter user details")
      expect(prompt.output.string).to include("2. Trial License")
      expect(prompt.output.string).to include("No. of units: Unlimited targets")
      expect(prompt.output.string).to include("Kindly complete the user registration at")
      expect(prompt.output.string).to include("Once you submit the details, you will receive the license ID on the email id you provided.")
      expect(prompt.output.string).to include("Validate license now")
    end
  end

  context "trial license restriction ux, user has an active trial license and tries to add another trial license via tui" do
    Dir.mktmpdir do |tmpdir|
      let(:argv) { ["--chef-license-key=#{valid_trial_license_key}"] }

      let(:lkf_opts) {
        {
          argv: argv,
          dir: tmpdir,
        }
      }

      let(:license_key_fetcher) { ChefLicensing::LicenseKeyFetcher.new(lkf_opts) }

      let(:start_interaction) { :add_license_all }
      let(:opts) {
        {
          prompt: prompt,
          interaction_file: interaction_file,
          dir: tmpdir,
        }
      }
      let(:tui_engine) { described_class.new(opts) }

      before do
        ChefLicensing::Context.current_context = nil
        license_key_fetcher.fetch_and_persist
      end

      it "checks if the license is persisted" do
        expect(license_key_fetcher.fetch).to eq([valid_trial_license_key])
      end

      before do
        prompt.input << "\n"
        prompt.input << valid_trial_license_key_2
        prompt.input << "\n"
        prompt.input.rewind
      end

      let(:expected_flow_for_license_restriction) {
        %i{
          add_license_all
          ask_if_user_has_license_id_for_license_addition
          ask_for_license_id
          validate_license_id_pattern
          validate_license_id_with_api
          validate_license_restriction
          prompt_error_license_addition_restricted
          license_restriction_header_text
          trial_already_exist_message
          add_license_info_in_restriction_flow
          license_restriction_foot_text
          only_commercial_allowed_message
          exit_with_message
        }
      }

      it "doesn't allow to add another free license key" do
        expect { tui_engine.run_interaction(start_interaction) }.to_not raise_error
        expect(tui_engine.traversed_interaction).to eq(expected_flow_for_license_restriction)
        expect(prompt.output.string).to include("✖ [Error] License validation failed")
        expect(prompt.output.string).to include("A Trial License already exists with following details:")
        expect(prompt.output.string).to include("Please generate a Commercial License by running")
      end
    end
  end

  context "trial license restriction ux, user has an expired trial license and tries to add another trial license via tui" do
    Dir.mktmpdir do |tmpdir|
      let(:argv) { ["--chef-license-key=#{expired_trial_license_key}"] }

      let(:lkf_opts) {
        {
          argv: argv,
          dir: tmpdir,
        }
      }

      let(:license_key_fetcher) { ChefLicensing::LicenseKeyFetcher.new(lkf_opts) }

      let(:start_interaction) { :add_license_all }
      let(:opts) {
        {
          prompt: prompt,
          interaction_file: interaction_file,
          dir: tmpdir,
        }
      }
      let(:tui_engine) { described_class.new(opts) }

      before do
        ChefLicensing::Context.current_context = nil
        license_key_fetcher.fetch_and_persist
      end

      it "checks if the license is persisted" do
        expect(license_key_fetcher.fetch).to eq([expired_trial_license_key])
      end

      before do
        prompt.input << "\n"
        prompt.input << valid_trial_license_key_2
        prompt.input << "\n"
        prompt.input.rewind
      end

      let(:expected_flow_for_license_restriction) {
        %i{
          add_license_all
          ask_if_user_has_license_id_for_license_addition
          ask_for_license_id
          validate_license_id_pattern
          validate_license_id_with_api
          validate_license_restriction
          prompt_error_license_addition_restricted
          license_restriction_header_text
          trial_already_exist_message
          add_license_info_in_restriction_flow
          license_restriction_foot_text
          trial_restriction_message
          exit_with_message
        }
      }

      it "doesn't allow to add another free license key" do
        expect { tui_engine.run_interaction(start_interaction) }.to_not raise_error
        expect(tui_engine.traversed_interaction).to eq(expected_flow_for_license_restriction)
        expect(prompt.output.string).to include("✖ [Error] License validation failed")
        expect(prompt.output.string).to include("A Trial License already exists with following details:")
        expect(prompt.output.string).to include("Please generate a Free Tier or Commercial License by running")
      end
    end
  end

  context "user executes with an expired trial license id" do
    # license_key_fetcher is responsible for setting the start_interaction to :prompt_license_expired
    let(:start_interaction) { :prompt_license_expired }
    let(:tui_engine) { described_class.new(opts) }

    it "shows the error message for expired license" do
      expect { tui_engine.append_info_to_input(additional_info_for_tui_engine) }.to_not raise_error
      expect { tui_engine.run_interaction(start_interaction) }.to_not raise_error
      expect(tui_engine.traversed_interaction).to eq(%i{prompt_license_expired fetch_license_id})
      expect(prompt.output.string).to include("License Expired")
      expect(prompt.output.string).to include("Get a Commercial License to receive bug fixes, updates")
      expect(prompt.output.string).to include("Get a Free Tier License to scan limited targets.")
      expect(prompt.output.string).to include("license add")
    end

  end

  context "user executes with an expired trial license id while using local licensing service" do
    # license_key_fetcher is responsible for setting the start_interaction to :prompt_license_expired_local_mode
    let(:start_interaction) { :prompt_license_expired_local_mode }
    let(:tui_engine) { described_class.new(opts) }

    it "shows the error message for expired license" do
      expect { tui_engine.append_info_to_input(additional_info_for_tui_engine) }.to_not raise_error
      expect { tui_engine.run_interaction(start_interaction) }.to_not raise_error
      expect(tui_engine.traversed_interaction).to eq(%i{prompt_license_expired_local_mode fetch_license_id})
      expect(prompt.output.string).to include("License Expired")
      expect(prompt.output.string).to include("Get a Commercial License to receive bug fixes, updates")
      expect(prompt.output.string).to include("Get a Free Tier License to scan limited targets.")
      expect(prompt.output.string).to_not include("license add")
    end

  end

  context "user executes with an about to expire trial license id" do
    # license_key_fetcher is responsible for setting the start_interaction to :prompt_license_about_to_expire
    let(:start_interaction) { :prompt_license_about_to_expire }
    let(:tui_engine) { described_class.new(opts) }

    it "shows the warning message for about to expire license" do
      expect { tui_engine.run_interaction(start_interaction) }.to_not raise_error
      expect(tui_engine.traversed_interaction).to eq(%i{prompt_license_about_to_expire fetch_license_id})
      expect(prompt.output.string).to include("Your license is about to expire in")
      expect(prompt.output.string).to include("To avoid service disruptions, get a Commercial License")
    end
  end

  context "user selects commercial license generation process via the inital prompts" do
    let(:start_interaction) { :start }

    before do
      prompt.input << simulate_down_arrow
      prompt.input << "\n"
      prompt.input << simulate_down_arrow
      prompt.input << simulate_down_arrow
      prompt.input << "\n"
      prompt.input << "\n"
      prompt.input.rewind
    end

    let(:tui_engine) { described_class.new(opts) }

    let(:expected_commercial_flow) {
      %i{
        start
        ask_if_user_has_license_id
        info_of_license_types
        filter_license_type_options
        ask_for_all_license_type
        commercial_license_selection
        exit_with_message
      }
    }

    it "generates the license successfully traversing through the interactions in expected order" do
      expect { tui_engine.run_interaction(start_interaction) }.to_not raise_error
      expect(tui_engine.traversed_interaction).to eq(expected_commercial_flow)
      expect(prompt.output.string).to include("I don't have a license ID and would like to generate a new license ID")
      expect(prompt.output.string).to include("Select the type of license below and then enter user details")
      expect(prompt.output.string).to include("3. Commercial License")
      expect(prompt.output.string).to include("Get in touch with the Sales Team by filling out the form available at")
    end
  end

  context "user selects commercial license generation process via the license add flow" do
    let(:start_interaction) { :add_license_all }

    before do
      prompt.input << simulate_down_arrow
      prompt.input << "\n"
      prompt.input << simulate_down_arrow
      prompt.input << simulate_down_arrow
      prompt.input << "\n"
      prompt.input << "\n"
      prompt.input.rewind
    end

    let(:tui_engine) { described_class.new(opts) }

    let(:expected_commercial_flow) {
      %i{
        add_license_all
        ask_if_user_has_license_id_for_license_addition
        info_of_license_types
        filter_license_type_options
        ask_for_all_license_type
        commercial_license_selection
        exit_with_message
      }
    }

    it "generates the license successfully traversing through the interactions in expected order" do
      expect { tui_engine.run_interaction(start_interaction) }.to_not raise_error
      expect(tui_engine.traversed_interaction).to eq(expected_commercial_flow)
      expect(prompt.output.string).to include("Generate a new license ID")
      expect(prompt.output.string).to include("Select the type of license below and then enter user details")
      expect(prompt.output.string).to include("3. Commercial License")
      expect(prompt.output.string).to include("Get in touch with the Sales Team by filling out the form available at")
    end
  end

  context "user adds a license invoking license add flow" do
    let(:start_interaction) { :add_license_all }

    before do
      prompt.input << "\n"
      prompt.input << valid_trial_license_key
      prompt.input << "\n"
      prompt.input.rewind
    end

    let(:tui_engine) { described_class.new(opts) }

    it "exits successfully traversing through the interactions in expected order" do
      expect { tui_engine.run_interaction(start_interaction) }.to_not raise_error
      expect(tui_engine.traversed_interaction).to eq(%i{add_license_all ask_if_user_has_license_id_for_license_addition ask_for_license_id validate_license_id_pattern validate_license_id_with_api validate_license_restriction validate_license_expiration validation_success display_license_info fetch_license_id})
      expect(prompt.output.string).to include("Validate a generated license ID")
      expect(prompt.output.string).to include("Please enter your license ID:")
      expect(prompt.output.string).to include("License validated successfully")
    end
  end

  context "user invokes license add flow and quits" do
    let(:start_interaction) { :add_license_all }

    before do
      prompt.input << simulate_down_arrow
      prompt.input << simulate_down_arrow
      prompt.input << "\n"
      prompt.input.rewind
    end

    let(:tui_engine) { described_class.new(opts) }

    it "exits successfully traversing through the interactions in expected order" do
      expect { tui_engine.run_interaction(start_interaction) }.to_not raise_error
      expect(tui_engine.traversed_interaction).to eq(%i{add_license_all ask_if_user_has_license_id_for_license_addition})
      expect(prompt.output.string).to include("Quit license addition")
    end
  end

  context "user skips the licensing generation process" do
    let(:start_interaction) { :start }

    before do
      prompt.input << simulate_down_arrow
      prompt.input << simulate_down_arrow
      prompt.input << "\n\n"
      prompt.input.rewind
    end

    let(:tui_engine) { described_class.new(opts) }

    let(:expected_skip_flow) {
      %i{
        start
        ask_if_user_has_license_id
        skip_message
        skip_licensing
        skipped
        exit_with_message
      }
    }

    it "skips the license generation process" do
      expect { tui_engine.run_interaction(start_interaction) }.to_not raise_error
      expect(tui_engine.traversed_interaction).to eq(expected_skip_flow)
      expect(prompt.output.string).to include("Skip")
      expect(prompt.output.string).to include("Are you sure to skip this step?")
      expect(prompt.output.string).to include("! [WARNING] A license is required to continue using this product")
      expect(prompt.output.string).to include("License ID validation skipped!")
    end
  end

  context "commercial license entry ux with exhausted limit" do
    let(:start_interaction) { :start }

    before do
      prompt.input << "\n"
      prompt.input << exhausted_commercial_license
      prompt.input << "\n"
      prompt.input.rewind
    end

    let(:tui_engine) { described_class.new(opts) }

    it "exits successfully traversing through the interactions in expected order" do
      expect { tui_engine.run_interaction(start_interaction) }.to_not raise_error
      expect(tui_engine.traversed_interaction).to eq(%i{start ask_if_user_has_license_id ask_for_license_id validate_license_id_pattern validate_license_id_with_api validate_license_restriction validate_license_expiration prompt_license_exhausted is_run_allowed_on_license_exhausted fetch_license_id})
      expect(prompt.output.string).to include("Commercial License Exhausted")
      expect(prompt.output.string).to include("We hope you've been enjoying Chef")
      expect(prompt.output.string).to include("However, it appears that you have exceeded your entitled usage limit")
    end
  end

  context "free license entry ux with exhausted limit" do
    let(:start_interaction) { :start }

    before do
      prompt.input << "\n"
      prompt.input << exhausted_free_license
      prompt.input << "\n"
      prompt.input.rewind
    end

    let(:tui_engine) { described_class.new(opts) }

    it "exits successfully traversing through the interactions in expected order" do
      expect { tui_engine.run_interaction(start_interaction) }.to_not raise_error
      expect(tui_engine.traversed_interaction).to eq(%i{start ask_if_user_has_license_id ask_for_license_id validate_license_id_pattern validate_license_id_with_api validate_license_restriction validate_license_expiration prompt_license_exhausted is_run_allowed_on_license_exhausted})
      expect(prompt.output.string).to include("Free License Exhausted")
      expect(prompt.output.string).to include("We hope you've been enjoying Chef")
      expect(prompt.output.string).to include("However, it appears that you have exceeded your entitled usage limit")
    end
  end
end
