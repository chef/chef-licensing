require_relative "../restful_client/v1"
require_relative "../exceptions/license_describe_error"
require_relative "../license"
require_relative "../config"

module ChefLicensing
  module Api
    class LicenseDescribe
      attr_reader :license_keys, :entitlement_id

      class << self
        def list(opts = {})
          new(opts).list
        end
      end

      def initialize(opts = {})
        @license_keys = opts[:license_keys] || raise(ArgumentError, "Missing Params: `license_keys`")
        @entitlement_id = opts[:entitlement_id] || raise(ArgumentError, "Missing Params: `entitlement_id`")
        @restful_client = opts[:restful_client] ? opts[:restful_client].new : ChefLicensing::RestfulClient::V1.new
      end

      def list
        response = restful_client.describe(license_keys: license_keys, entitlement_id: entitlement_id)
        if response.data
          list_of_licenses = []

          response.data["license"].each do |license|

            # license object created to be fed to parser
            license_object = {
              "license": license,
              "assets": response.data["assets"],
              "features": response.data["features"],
              "software": response.data["software"],
            }

            list_of_licenses << ChefLicensing::License.new(
              data: license_object,
              product_name: ChefLicensing.chef_product_name,
              api_parser: ChefLicensing::Api::Parser::Describe
            )
          end
          # returns list of license data model object
          list_of_licenses
        else
          raise(ChefLicensing::LicenseDescribeError, response.message)
        end
      end

      private

      attr_reader :restful_client
    end
  end
end