require_relative "../restful_client/v1"
require_relative "../exceptions/client_error"
require_relative "../license"
require_relative "../config"

module ChefLicensing
  module Api
    class Client
      attr_reader :license_keys, :entitlement_id

      class << self
        def info(opts = {})
          new(opts).info
        end

        def clear_client_cache(opts = {})
          new(opts).clear_client_cache
        end
      end

      def initialize(opts = {})
        @license_keys = opts[:license_keys] || raise(ArgumentError, "Missing Params: `license_keys`")
        @restful_client = opts[:restful_client] ? opts[:restful_client].new : ChefLicensing::RestfulClient::V1.new
      end

      def info
        response = restful_client.client(license_keys: license_keys.join(","), entitlement_id: ChefLicensing::Config.chef_entitlement_id)
        if response.data
          ChefLicensing::License.new(
            data: response.data,
            api_parser: ChefLicensing::Api::Parser::Client
          )
        else
          raise(ChefLicensing::ClientError, response.message)
        end
      end

      def clear_client_cache
        restful_client.clear_cache(ChefLicensing::RestfulClient::V1::END_POINTS[:CLIENT], { licenseId: license_keys.join(","), entitlementId: ChefLicensing::Config.chef_entitlement_id })
      end

      private

      attr_reader :restful_client
    end
  end
end
