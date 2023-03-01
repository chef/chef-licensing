require "faraday" unless defined?(Faraday)
require "faraday/http_cache"
require "active_support"
require "tmpdir" unless defined?(Dir.mktmpdir)
require_relative "../exceptions/restful_client_error"
require_relative "../config"

module ChefLicensing
  module RestfulClient

    # Base class to handle all License Server endpoints
    class Base

      END_POINTS = {
        VALIDATE: "validate",
        GENERATE_LICENSE: "triallicense",
        FEATURE_BY_NAME: "license-service/featurebyname",
        FEATURE_BY_ID: "license-service/featurebyid",
        ENTITLEMENT_BY_NAME: "license-service/entitlementbyname",
        ENTITLEMENT_BY_ID: "license-service/entitlementbyid",
        CLIENT: "client",
        DESCRIBE: "desc",
      }.freeze

      CURRENT_ENDPOINT_VERSION = 2

      def initialize; end

      def validate(license)
        handle_get_connection do |connection|
          connection.get(self.class::END_POINTS[:VALIDATE], { licenseId: license, version: CURRENT_ENDPOINT_VERSION }).body
        end
      end

      def generate_license(payload)
        handle_post_connection do |connection|
          response = connection.post(self.class::END_POINTS[:GENERATE_LICENSE]) do |request|
            request.body = payload.to_json
            request.headers = { 'x-api-key': ChefLicensing::Config.license_server_api_key }
          end
          raise RestfulClientError, format_error_from(response) unless response.success?

          response.body
        end
      end

      def feature_by_name(payload)
        handle_post_connection do |connection|
          response = connection.post(self.class::END_POINTS[:FEATURE_BY_NAME]) do |request|
            request.body = payload.to_json
          end
          raise RestfulClientError, format_error_from(response) unless response.success?

          response.body
        end
      end

      def feature_by_id(payload)
        handle_post_connection do |connection|
          response = connection.post(self.class::END_POINTS[:FEATURE_BY_ID]) do |request|
            request.body = payload.to_json
          end
          raise RestfulClientError, format_error_from(response) unless response.success?

          response.body
        end
      end

      def entitlement_by_name(payload)
        handle_post_connection do |connection|
          response = connection.post(self.class::END_POINTS[:ENTITLEMENT_BY_NAME]) do |request|
            request.body = payload.to_json
          end
          raise RestfulClientError, format_error_from(response) unless response.success?

          response.body
        end
      end

      def entitlement_by_id(payload)
        handle_post_connection do |connection|
          response = connection.post(self.class::END_POINTS[:ENTITLEMENT_BY_ID]) do |request|
            request.body = payload.to_json
          end
          raise RestfulClientError, format_error_from(response) unless response.success?

          response.body
        end
      end

      def client(params = {})
        handle_get_connection do |connection|
          connection.get(self.class::END_POINTS[:CLIENT], { licenseId: params[:license_keys], entitlementId: params[:entitlement_id] }).body
        end
      end

      def describe(params = {})
        handle_get_connection do |connection|
          connection.get(self.class::END_POINTS[:DESCRIBE], { licenseId: params[:license_keys], entitlementId: params[:entitlement_id] }).body
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

      private

      def get_connection
        store = ::ActiveSupport::Cache.lookup_store(:file_store, [Dir.tmpdir])
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
