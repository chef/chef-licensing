require_relative "../restful_client/v1"
require_relative "../exceptions/client_error"
require_relative "../license"
require_relative "../config"
require_relative "../restful_client/cache_manager"

module ChefLicensing
  module Api
    class Client
      attr_reader :license_keys, :entitlement_id

      class << self
        def info(opts = {})
          new(opts).info
        end
      end

      def initialize(opts = {})
        @license_keys = opts[:license_keys] || raise(ArgumentError, "Missing Params: `license_keys`")
        @restful_client = opts[:restful_client] ? opts[:restful_client].new : ChefLicensing::RestfulClient::V1.new
        @cache_manager = opts[:cache_manager] || ChefLicensing::RestfulClient::CacheManager.new
      end

      def info
        cache_key = license_keys.join(",")
        @cache_manager.fetch(cache_key) do
          license = fetch_license
          @cache_manager.store(cache_key, license, ttl_cache)
          license
        end
      end

      private

      attr_reader :restful_client, :ttl_cache

      def fetch_license
        response = restful_client.client(license_keys: license_keys.join(","), entitlement_id: ChefLicensing::Config.chef_entitlement_id)
        if response.data
          @ttl_cache = response.data.cache.expires
          ChefLicensing::License.new(
            data: response.data,
            api_parser: ChefLicensing::Api::Parser::Client
          )
        else
          raise(ChefLicensing::ClientError, response.message)
        end
      end
    end
  end
end
