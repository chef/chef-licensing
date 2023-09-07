require "spec_helper"
require "chef-licensing/restful_client/api_gateway"
require "chef-licensing/config"
require "chef-licensing/restful_client/cache_manager"

RSpec.describe ChefLicensing::RestfulClient::ApiGateway do
  let(:output) { StringIO.new }
  let(:logger) { Logger.new(output) }

  context "invoking methods of api gateway" do
    Dir.mktmpdir do |dir|
      let(:cache_manager) { ChefLicensing::RestfulClient::CacheManager.new(dir) }
      let(:api_gateway) { described_class.new({ cache_manager: cache_manager }) }

      before do
        ChefLicensing.configure do |config|
          config.logger = logger
          config.output = output
          config.license_server_url = "http://globalhost-license-server/License"
          config.license_server_url_check_in_file = true
          config.chef_product_name = "inspec"
          config.chef_entitlement_id = "3ff52c37-e41f-4f6c-ad4d-365192205968"
          config.cache_enabled = true
        end
      end

      # stub a dummy get request to the license server
      before do
        stub_request(:get, "#{ChefLicensing::Config.license_server_url}/dummy_endpoint")
          .with(query: {})
          .to_return(body: { data: true, message: "You have reached the server", status_code: 200 }.to_json,
                    headers: { content_type: "application/json" })
      end

      # stub a dummy post request to the license server
      before do
        stub_request(:post, "#{ChefLicensing::Config.license_server_url}/dummy_endpoint")
          .with(body: {}.to_json)
          .to_return(body: { data: true, message: "You have posted to server", status_code: 200 }.to_json,
                      headers: { content_type: "application/json" })
      end

      describe "#fetch_from_server" do
        it "fetches the response from the server" do
          expect(api_gateway.fetch_from_server("dummy_endpoint")).to be_truthy
          expect(output.string).to include("Fetching data from server for dummy_endpoint")
          expect(output.string).to_not include("Storing data in cache for dummy_endpoint")
        end
      end

      describe "#fetch_from_cache_or_server" do
        it "fetches the response from server and caches it" do
          expect(api_gateway.fetch_from_cache_or_server("dummy_endpoint")).to be_truthy
          expect(output.string).to include("Fetching data from server for dummy_endpoint")
          expect(output.string).to include("Storing data in cache for dummy_endpoint")
        end

        it "fetches the response from cache at next invocation; after it is cached" do
          expect(api_gateway.fetch_from_cache_or_server("dummy_endpoint")).to be_truthy
          expect(output.string).to include("Cache found for dummy_endpoint")
        end
      end

      describe "#clear_cached_response" do
        it "clears the cached response" do
          expect(api_gateway.clear_cached_response("dummy_endpoint")).to be_truthy
          expect(output.string).to include("Clearing cache for dummy_endpoint")
        end
      end

      describe "#fetch_from_server_or_cache" do

        it "fetches the response from server and caches it" do
          expect(api_gateway.fetch_from_server_or_cache("dummy_endpoint")).to be_truthy
          expect(output.string).to include("Fetching data from server for dummy_endpoint")
          expect(output.string).to include("Storing cache for dummy_endpoint")
        end

        it "fetches from the server, and does not rely on cache" do
          expect(api_gateway.fetch_from_server_or_cache("dummy_endpoint")).to be_truthy
          expect(output.string).to include("Fetching data from server for dummy_endpoint")
          expect(output.string).to include("Storing cache for dummy_endpoint")
          expect(output.string).to_not include("Falling back to cache for dummy_endpoint")
        end

        # make the server unreachable
        before do
          stub_request(:get, "#{ChefLicensing::Config.license_server_url}/dummy_endpoint_2")
            .with(query: {})
            .to_raise(ChefLicensing::RestfulClientConnectionError)
        end

        # make a dummy cache entry
        before do
          cache_key = cache_manager.construct_cache_key("dummy_endpoint_2", {})
          cache_manager.store(cache_key, "data")
        end

        it "fetches from the cache when the server is unreachable" do
          expect(api_gateway.fetch_from_server_or_cache("dummy_endpoint_2")).to be_truthy
          expect(output.string).to include("Fetching data from server for dummy_endpoint_2")
          expect(output.string).to include("Falling back to cache for dummy_endpoint_2")
        end
      end

      describe "#post_to_server" do
        it "posts to the server" do
          expect(api_gateway.post_to_server("dummy_endpoint")).to be_truthy
        end
      end
    end
  end
end
