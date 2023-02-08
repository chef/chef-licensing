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
      end

      def initialize(opts = {})
        @license_keys = opts[:license_keys] || raise(ArgumentError, "Missing Params: `license_keys`")
        @cl_config = opts[:cl_config] || ChefLicensing::Config.instance
        @restful_client = opts[:restful_client] ? opts[:restful_client].new(cl_config: cl_config) : ChefLicensing::RestfulClient::V1.new(cl_config: cl_config)
        @entitlement_id = cl_config.chef_entitlement_id || raise(ArgumentError, "Please set CHEF_ENTITLEMENT_ID in env or pass it using argument --chef-entitlement-id")
      end

      def info
        response = restful_client.client(license_keys: license_keys.join(","), entitlement_id: entitlement_id)
        if response.data
          ChefLicensing::License.new(
            data: response.data,
            api_parser: ChefLicensing::Api::Parser::Client,
            cl_config: cl_config
          )
        else
          raise(ChefLicensing::ClientError, response.message)
        end
      end

      private

      attr_reader :restful_client, :cl_config
    end
  end
end