require "spec_helper"
require "chef-licensing/config"
require "chef-licensing/restful_client/v1"
require "chef-licensing/restful_client/cache_manager"

RSpec.describe ChefLicensing::RestfulClient::V1 do
  let(:output) { StringIO.new }
  let(:logger) { Logger.new(output) }
  let(:free_license_key) { "free-c0832d2d-1111-1ec1-b1e5-011d182dc341-111" }

  context "when one license_server_url is set" do
    before do
      ChefLicensing.configure do |config|
        config.logger = logger
        config.output = output
        config.license_server_url = "http://globalhost-license-server/License"
        config.license_server_url_check_in_file = true
        config.chef_product_name = "inspec"
        config.chef_entitlement_id = "3ff52c37-e41f-4f6c-ad4d-365192205968"
        config.cache_enabled = false
      end
    end

    before do
      stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/validate")
        .with(query: { licenseId: free_license_key, version: 2 })
        .to_return(body: { data: true, message: "License Id is valid", status_code: 200 }.to_json,
                  headers: { content_type: "application/json" })
    end

    let(:base_obj) { described_class.new }

    it "invokes the endpoint with the specified license_server_url" do
      expect(base_obj.validate(free_license_key).data).to eq(true)
    end
  end

  context "when multiple license_server_url is set" do
    before do
      ChefLicensing.configure do |config|
        config.logger = logger
        config.output = output
        config.license_server_url = "http://localhost-1-license-server/License,http://localhost-2-license-server/License"
        config.license_server_url_check_in_file = true
        config.chef_product_name = "inspec"
        config.chef_entitlement_id = "3ff52c37-e41f-4f6c-ad4d-365192205968"
        config.cache_enabled = false
      end
    end

    before do
      # stub the first url to be unreachable
      stub_request(:get, "http://localhost-1-license-server/License/v1/validate")
        .with(query: { licenseId: free_license_key, version: 2 })
        .to_raise(Errno::ECONNREFUSED)

      stub_request(:get, "http://localhost-2-license-server/License/v1/validate")
        .with(query: { licenseId: free_license_key, version: 2 })
        .to_return(body: { data: true, message: "License Id is valid", status_code: 200 }.to_json,
                  headers: { content_type: "application/json" })
    end

    let(:base_obj) { described_class.new }

    it "finds a URL which is reachable and invokes the endpoint with that URL" do
      expect(base_obj.validate(free_license_key).data).to eq(true)
      expect(output.string).to include("Connection succeeded to http://localhost-2-license-server/License")
      expect(output.string).to include("Connection failed to http://localhost-1-license-server/License")
      # it updates the config with the reachable URL
      expect(ChefLicensing::Config.license_server_url).to eq("http://localhost-2-license-server/License")
    end
  end

  context "when multiple license_server_url is set in config with space after comma" do
    before do
      ChefLicensing.configure do |config|
        config.logger = logger
        config.output = output
        config.license_server_url = "http://localhost-1-license-server/License, http://localhost-2-license-server/License"
        config.license_server_url_check_in_file = true
        config.chef_product_name = "inspec"
        config.chef_entitlement_id = "3ff52c37-e41f-4f6c-ad4d-365192205968"
        config.cache_enabled = false
      end
    end

    before do
      # stub the first url to be unreachable
      stub_request(:get, "http://localhost-1-license-server/License/v1/validate")
        .with(query: { licenseId: free_license_key, version: 2 })
        .to_raise(Errno::ECONNREFUSED)

      stub_request(:get, "http://localhost-2-license-server/License/v1/validate")
        .with(query: { licenseId: free_license_key, version: 2 })
        .to_return(body: { data: true, message: "License Id is valid", status_code: 200 }.to_json,
                  headers: { content_type: "application/json" })
    end

    let(:base_obj) { described_class.new }

    it "finds a URL which is reachable and invokes the endpoint with that URL" do
      expect(base_obj.validate(free_license_key).data).to eq(true)
      expect(output.string).to include("Connection succeeded to http://localhost-2-license-server/License")
      expect(output.string).to include("Connection failed to http://localhost-1-license-server/License")
      # it updates the config with the reachable URL
      expect(ChefLicensing::Config.license_server_url).to eq("http://localhost-2-license-server/License")
    end
  end

  context "when bad license_server_url is set in config with comma" do
    before do
      ChefLicensing.configure do |config|
        config.logger = logger
        config.output = output
        config.license_server_url = "http://www.exa-mple.com?catid=123&prodid=456!@#$%^&*, http://localhost-2-license-server/License"
        config.license_server_url_check_in_file = true
        config.chef_product_name = "inspec"
        config.chef_entitlement_id = "3ff52c37-e41f-4f6c-ad4d-365192205968"
        config.cache_enabled = false
      end
    end

    before do
      # stub the first url to be unreachable
      stub_request(:get, "http://localhost-1-license-server/License/v1/validate")
        .with(query: { licenseId: free_license_key, version: 2 })
        .to_raise(URI::InvalidURIError)

      stub_request(:get, "http://localhost-2-license-server/License/v1/validate")
        .with(query: { licenseId: free_license_key, version: 2 })
        .to_return(body: { data: true, message: "License Id is valid", status_code: 200 }.to_json,
                  headers: { content_type: "application/json" })
    end

    let(:base_obj) { described_class.new }

    it "finds a URL which is reachable and invokes the endpoint with that URL" do
      expect(base_obj.validate(free_license_key).data).to eq(true)
      expect(output.string).to include("Connection succeeded to http://localhost-2-license-server/License")
      expect(output.string).to include("Invalid URI http://www.exa-mple.com?catid=123&prodid=456!@#$%^&*")
      # it updates the config with the reachable URL
      expect(ChefLicensing::Config.license_server_url).to eq("http://localhost-2-license-server/License")
    end
  end

  context "when more than 5 license_server_url is set in config" do

    let(:urls) { "http://localhost-2-license-server/License, http://localhost-2-license-server/License, http://localhost-2-license-server/License, http://localhost-2-license-server/License, http://localhost-2-license-server/License, http://localhost-2-license-server/License, http://localhost-2-license-server/License" }

    before do
      ChefLicensing.configure do |config|
        config.logger = logger
        config.output = output
        config.license_server_url = urls
        config.license_server_url_check_in_file = true
        config.chef_product_name = "inspec"
        config.chef_entitlement_id = "3ff52c37-e41f-4f6c-ad4d-365192205968"
        config.cache_enabled = false
      end
    end

    before do
      # stub the first url to be unreachable
      stub_request(:get, "http://localhost-2-license-server/License/v1/validate")
        .with(query: { licenseId: free_license_key, version: 2 })
        .to_raise(Errno::ECONNREFUSED)
    end

    let(:base_obj) { described_class.new }

    it "breaks after 5th attempt and raises an error" do
      expect { base_obj.validate(free_license_key) }.to raise_error(ChefLicensing::RestfulClientConnectionError, /Unable to connect to the licensing server. inspec requires server communication to operate/ )
      expect(output.string).to include("Only the first 5 urls will be tried")
      expect(output.string).to include("Connection failed to http://localhost-2-license-server/License")
    end
  end
end
