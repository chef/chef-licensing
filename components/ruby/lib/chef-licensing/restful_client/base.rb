require_relative "../exceptions/missing_api_credentials_error"
require_relative "../config"
require_relative "api_gateway"

module ChefLicensing
  module RestfulClient

    # Base class to handle all License Server endpoints
    class Base

      END_POINTS = {
        FEATURE_BY_NAME: "license-service/featurebyname",
        FEATURE_BY_ID: "license-service/featurebyid",
        ENTITLEMENT_BY_NAME: "license-service/entitlementbyname",
        ENTITLEMENT_BY_ID: "license-service/entitlementbyid",
      }.freeze

      # Cache first endpoints are the endpoints where we want to fetch data from cache first
      # and if it fails, fallback to server
      CACHE_FIRST_ENDPOINTS = [
      ].freeze

      # API first endpoints are the endpoints where we want to fetch data from server first
      # and if it fails, fallback to cache
      API_FIRST_ENDPOINTS = [
      ].freeze

      CURRENT_ENDPOINT_VERSION = 2

      def initialize(opts = {})
        raise MissingAPICredentialsError, "Missing credential in config: Set in block chef_license_server or use environment variable CHEF_LICENSE_SERVER or pass through argument --chef-license-server" if ChefLicensing::Config.license_server_url.nil?

        @logger = ChefLicensing::Config.logger
        @api_gateway = opts[:api_gateway] || ChefLicensing::RestfulClient::ApiGateway.new(opts)
      end

      def validate(license)
        invoke_get_api(self.class::END_POINTS[:VALIDATE], { licenseId: license, version: CURRENT_ENDPOINT_VERSION })
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

      def clear_cached_response(endpoint, params = {})
        logger.debug("Clearing cache for #{endpoint} with params #{params}")
        @api_gateway.clear_cached_response(endpoint, params)
      end

      private

      attr_reader :logger

      # a common method to handle the get API calls
      def invoke_get_api(endpoint, params = {})
        if self.class::API_FIRST_ENDPOINTS.include?(endpoint) && ChefLicensing::Config.cache_enabled?
          @api_gateway.fetch_from_server_or_cache(endpoint, params)
        elsif self.class::CACHE_FIRST_ENDPOINTS.include?(endpoint) && ChefLicensing::Config.cache_enabled?
          @api_gateway.fetch_from_cache_or_server(endpoint, params)
        else
          @api_gateway.fetch_from_server(endpoint, params)
        end
      end

      # a common method to handle the post API calls
      def invoke_post_api(endpoint, payload, headers = {})
        @api_gateway.post_to_server(endpoint, payload, headers)
      end
    end
  end
end
