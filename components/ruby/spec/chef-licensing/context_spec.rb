require "chef-licensing/context"
require "chef-licensing"

RSpec.describe ChefLicensing::Context do
  let(:output) { StringIO.new }
  let(:logger) {
    log = Object.new
    log.extend(Mixlib::Log)
    log.init(output)
    log
  }
  let(:client_api_data) { JSON.parse(File.read("spec/fixtures/api_response_data/valid_client_api_response.json")) }
  let(:argv) { [] }
  let(:env) { {} }
  let(:opts) {
    {
      dir: Dir.mktmpdir,
      output: output,
      logger: logger,
      argv: argv,
      env: env,
    }
  }

  before do
    ChefLicensing.configure do |config|
      config.chef_product_name = "inspec"
      config.chef_entitlement_id = "3ff52c37-e41f-4f6c-ad4d-365192205968"
      config.license_server_url = "http://localhost-license-server/License"
      config.is_local_license_service = nil
    end
    ChefLicensing::Context.current_context = nil
    stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/listLicenses")
      .to_return(body: { data: ["tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150"], status_code: 200 }.to_json,
        headers: { content_type: "application/json" })
    stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
      .with(query: { licenseId: "tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150", entitlementId: ChefLicensing::Config.chef_entitlement_id })
      .to_return(body: { data: client_api_data, status_code: 200 }.to_json,
        headers: { content_type: "application/json" })
  end

  describe "Fetching license context" do
    it "returns license context succesfully" do
      expect(ChefLicensing::Context.license.class).to eq(ChefLicensing::License)
    end
  end
end
