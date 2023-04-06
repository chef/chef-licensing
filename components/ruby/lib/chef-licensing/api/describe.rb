require_relative "../restful_client/v1"
require_relative "../exceptions/describe_error"
require_relative "../license"
require_relative "../config"
require "ostruct" unless defined?(OpenStruct)

module ChefLicensing
  module Api
    class Describe
      attr_reader :license_keys

      class << self
        def list(opts = {})
          new(opts).list
        end
      end

      def initialize(opts = {})
        @license_keys = opts[:license_keys] || raise(ArgumentError, "Missing Params: `license_keys`")
        @restful_client = opts[:restful_client] ? opts[:restful_client].new : ChefLicensing::RestfulClient::V1.new
      end

      def list
        response = restful_client.describe(license_keys: license_keys.join(","), entitlement_id: ChefLicensing::Config.chef_entitlement_id)

        raise(ChefLicensing::DescribeError, response.message) unless response.data

        raise(ChefLicensing::DescribeError, "No license details found for the given license keys") unless response.data.license

        list_of_licenses = []

        response.data&.license&.each do |license|
          # license object created to be fed to parser
          license_object = OpenStruct.new({
            "license" => license,
            "assets" => response.data.Assets,
            "features" => response.data.Features,
            "software" => response.data.Software,
          })

          list_of_licenses << ChefLicensing::License.new(
            data: license_object,
            product_name: ChefLicensing::Config.chef_product_name,
            api_parser: ChefLicensing::Api::Parser::Describe
          )
        end
        # returns list of license data model object
        list_of_licenses
      end

      private

      attr_reader :restful_client
    end
  end
end