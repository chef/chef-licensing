require "faraday" unless defined?(Faraday)
require "faraday/http_cache"
require "active_support"
require "tmpdir" unless defined?(Dir.mktmpdir)
require_relative "../exceptions/restful_client_error"
require_relative "../exceptions/missing_api_credentials_error"
require_relative "../config"

module ChefLicensing
  module RestfulClient

    # Base class to handle all License Server endpoints
    class Base

      END_POINTS = {
        VALIDATE: "validate",
        GENERATE_TRIAL_LICENSE: "trial",
        GENERATE_FREE_LICENSE: "free",
        FEATURE_BY_NAME: "license-service/featurebyname",
        FEATURE_BY_ID: "license-service/featurebyid",
        ENTITLEMENT_BY_NAME: "license-service/entitlementbyname",
        ENTITLEMENT_BY_ID: "license-service/entitlementbyid",
        CLIENT: "client",
        DESCRIBE: "desc",
        LIST_LICENSES: "listlicenses",
      }.freeze

      CURRENT_ENDPOINT_VERSION = 2

      def initialize
        raise MissingAPICredentialsError, "Missing credential in config: Set in block chef_license_server or use environment variable CHEF_LICENSE_SERVER or pass through argument --chef-license-server" if ChefLicensing::Config.license_server_url.nil?

        # License server API key is only used for License generation API
        raise MissingAPICredentialsError, "Missing credential in config: Set in block chef_license_server_api_key or use environment variable CHEF_LICENSE_SERVER_API_KEY or pass through argument --chef-license-server-api-key" if ChefLicensing::Config.license_server_api_key.nil?
      end

      def validate(license)
        invoke_get_api(self.class::END_POINTS[:VALIDATE], { licenseId: license, version: CURRENT_ENDPOINT_VERSION })
      end

      def generate_trial_license(payload)
        headers = { 'x-api-key': ChefLicensing::Config.license_server_api_key }
        invoke_post_api(self.class::END_POINTS[:GENERATE_TRIAL_LICENSE], payload, headers)
      end

      def generate_free_license(payload)
        headers = { 'x-api-key': ChefLicensing::Config.license_server_api_key }
        invoke_post_api(self.class::END_POINTS[:GENERATE_FREE_LICENSE], payload, headers)
      end

      def feature_by_name(payload)
        invoke_post_api(self.class::END_POINTS[:FEATURE_BY_NAME], payload)
      end

      def feature_by_id(payload)
        invoke_post_api(self.class::END_POINTS[:FEATURE_BY_ID], payload)
      end

      def entitlement_by_name(payload)
        invoke_post_api(self.class::END_POINTS[:ENTITLEMENT_BY_NAME], payload)
      end

      def entitlement_by_id(payload)
        invoke_post_api(self.class::END_POINTS[:ENTITLEMENT_BY_ID], payload)
      end

      def client(params = {})
        invoke_get_api(self.class::END_POINTS[:CLIENT], { licenseId: params[:license_keys], entitlementId: params[:entitlement_id] })
      end

      def describe(params = {})
        invoke_get_api(self.class::END_POINTS[:DESCRIBE], { licenseId: params[:license_keys], entitlementId: params[:entitlement_id] })
      end

      def list_licenses(params = {})
        invoke_get_api(self.class::END_POINTS[:LIST_LICENSES])
      end

      private

      # a common method to handle the get API calls
      def invoke_get_api(endpoint, params = {})
        handle_get_connection do |connection|
          connection.get(endpoint, params).body
        end
      end

      # a common method to handle the post API calls
      def invoke_post_api(endpoint, payload, headers = {})
        handle_post_connection do |connection|
          response = connection.post(endpoint) do |request|
            request.body = payload.to_json
            request.headers = headers
          end
          raise RestfulClientError, format_error_from(response) unless response.success?

          response.body
        end
      end

      def handle_get_connection
        # handle faraday errors
        yield get_connection
      rescue Faraday::ClientError => e
        # log errors
        raise RestfulClientError, e.message
      end

      def handle_post_connection
        # handle faraday errors
        yield post_connection
      rescue Faraday::ClientError => e
        # log errors
        raise RestfulClientError, e.message
      end

      def get_connection
        store = ::ActiveSupport::Cache.lookup_store(:file_store, Dir.tmpdir)
        Faraday.new(url: ChefLicensing::Config.license_server_url) do |config|
          config.request :json
          config.response :json, parser_options: { object_class: OpenStruct }
          config.use Faraday::HttpCache, shared_cache: false, logger: ChefLicensing::Config.logger, store: store
          config.adapter Faraday.default_adapter
        end
      end

      def post_connection
        Faraday.new(url: ChefLicensing::Config.license_server_url) do |config|
          config.request :json
          config.response :json, parser_options: { object_class: OpenStruct }
        end
      end

      def format_error_from(response)
        error_details = response.body&.data&.error
        return response.reason_phrase unless error_details

        error_details
      end
    end
  end
end
