require_relative "../restful_client/v1"
require_relative "../exceptions/license_client_error"
require_relative "../license"
require_relative "../config"

module ChefLicensing
  module Api
    class LicenseClient
      attr_reader :license_keys, :entitlement_id

      class << self
        def client(opts = {})
          new(opts).client
        end
      end

      def initialize(opts = {})
        @license_keys = opts[:license_keys] || raise(ArgumentError, "Missing Params: `license_keys`")
        @entitlement_id = opts[:entitlement_id] || raise(ArgumentError, "Missing Params: `entitlement_id`")
        @cl_config = opts[:cl_config] || ChefLicensing::Config.instance
        @restful_client = opts[:restful_client] ? opts[:restful_client].new : ChefLicensing::RestfulClient::V1.new(cl_config: cl_config)
      end

      def client
        response = restful_client.client(license_keys: license_keys, entitlement_id: entitlement_id)
        if response.data
          ChefLicensing::License.new(
            data: response.data,
            product_name: cl_config.chef_product_name,
            api_parser: ChefLicensing::Api::Parser::Client
          )
        else
          raise(ChefLicensing::LicenseClientError, response.message)
        end
      end

      private

      attr_reader :restful_client, :cl_config
    end
  end
end