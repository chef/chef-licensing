require_relative "../restful_client/v1"
require_relative "../exceptions/license_describe_error"
require_relative "../license"
require_relative "../config"
require "ostruct" unless defined?(OpenStruct)

module ChefLicensing
  module Api
    class LicenseDescribe
      attr_reader :license_keys

      class << self
        def list(opts = {})
          new(opts).list
        end
      end

      def initialize(opts = {})
        @license_keys = opts[:license_keys] || raise(ArgumentError, "Missing Params: `license_keys`")
        @cl_config = opts[:cl_config] || ChefLicensing::Config.instance
        @restful_client = opts[:restful_client] ? opts[:restful_client].new : ChefLicensing::RestfulClient::V1.new(cl_config: cl_config)
      end

      def list
        response = restful_client.describe(license_keys: license_keys.join(","), entitlement_id: cl_config.chef_entitlement_id)
        if response.data
          list_of_licenses = []

          response.data.license.each do |license|

            # license object created to be fed to parser
            license_object = OpenStruct.new({
              "license" => license,
              "assets" => response.data.Assets,
              "features" => response.data.Features,
              "software" => response.data.Software,
            })

            list_of_licenses << ChefLicensing::License.new(
              data: license_object,
              product_name: cl_config.chef_product_name,
              api_parser: ChefLicensing::Api::Parser::Describe,
              cl_config: cl_config
            )
          end
          # returns list of license data model object
          list_of_licenses
        else
          raise(ChefLicensing::LicenseDescribeError, response.message)
        end
      end

      private

      attr_reader :restful_client, :cl_config
    end
  end
end