require "tty-prompt"
require "chef-licensing/license_key_fetcher/prompt"
require "logger"

RSpec.describe ChefLicensing::LicenseKeyFetcher::Prompt do
  let(:output) { StringIO.new }
  let(:logger) { Logger.new(output) }

  let(:interaction_file) { File.join("lib/chef-licensing/license_key_fetcher", "chef_licensing_interactions.yaml") }
  let(:output) { StringIO.new }
  let(:logger) { Logger.new(output) }
  let(:valid_trial_license_key) { "tmns-58555821-925e-4a27-8fdc-e79dae5a425b-1234" }
  let(:valid_client_api_data) { JSON.parse(File.read("spec/fixtures/api_response_data/valid_client_api_response.json")) }
  let(:valid_describe_api_data) { JSON.parse(File.read("spec/fixtures/api_response_data/valid_describe_api_response.json")) }

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
      config.air_gap_status = false
      config.chef_product_name = "inspec"
      config.chef_entitlement_id = "3ff52c37-e41f-4f6c-ad4d-365192205968"
    end
  end

  before do
    stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/listLicenses")
      .to_return(body: { data: [], status_code: 403 }.to_json,
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

    stub_request(:post, "#{ChefLicensing::Config.license_server_url}/v1/trial")
      .with(body: user_details_payload.to_json)
      .to_return(body: trial_license_generation_success_response,
                headers: { content_type: "application/json" })

  end

  context "when the user chooses to input license id" do

    before do
      prompt.input << "\n"
      prompt.input << valid_trial_license_key
      prompt.input << "\n"
      prompt.input.rewind
    end

    it "should do validate and return license id" do
      expect(described_class.new(opts).fetch).to eq([valid_trial_license_key])
    end
  end

  context "when the user chooses to generate a license id" do
    before do
      prompt.input << simulate_down_arrow
      prompt.input << "\n"
      prompt.input << simulate_down_arrow
      prompt.input << "\n"
      prompt.input << "\nJohn\nDoe\njohndoe@chef.com\nProgress Chef\n123-456-7890\n\n"
      prompt.input << valid_trial_license_key
      prompt.input << "\n"
      prompt.input.rewind
    end

    it "should do generate and return license id" do
      expect(described_class.new(opts).fetch).to eq([valid_trial_license_key])
    end
  end

  context "when the user skips the prompts" do
    before do
      prompt.input << simulate_down_arrow
      prompt.input << simulate_down_arrow
      prompt.input << "\n\n"
      prompt.input.rewind
    end
    it "should do exit" do
      expect( described_class.new(opts).fetch ).to eq([])
    end
  end
end