require "faraday" unless defined?(Faraday)
require "faraday/http_cache"
require "active_support"
require "active_support/time"
require "tmpdir" unless defined?(Dir.mktmpdir)
require_relative "../exceptions/restful_client_error"
require_relative "../exceptions/restful_client_connection_error"
require_relative "../exceptions/missing_api_credentials_error"
require_relative "../config"
require_relative "middleware/exceptions_handler"
require_relative "cache_manager"
require "digest" unless defined?(Digest)

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

      CACHE_FIRST_ENDPOINTS = [
      ].freeze

      API_FALLBACK_ENDPOINTS = [
      ].freeze

      CURRENT_ENDPOINT_VERSION = 2
      REQUEST_LIMIT = 5

      def initialize(opts = {})
        raise MissingAPICredentialsError, "Missing credential in config: Set in block chef_license_server or use environment variable CHEF_LICENSE_SERVER or pass through argument --chef-license-server" if ChefLicensing::Config.license_server_url.nil?

        @cache_manager = opts[:cache_manager] || ChefLicensing::RestfulClient::CacheManager.new
        @logger = ChefLicensing::Config.logger
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

      def clear_cache(endpoint, params = {})
        logger.debug("Clearing cache for #{endpoint} with params #{params}")
        cache_key = @cache_manager.construct_cache_key(endpoint, params)
        @cache_manager.delete(cache_key)
      end

      private

      attr_reader :logger

      # a common method to handle the get API calls
      def invoke_get_api(endpoint, params = {})
        if self.class::API_FALLBACK_ENDPOINTS.include?(endpoint) && ChefLicensing::Config.cache_enabled?
          perform_api_fallback_operation(endpoint, params)
        elsif self.class::CACHE_FIRST_ENDPOINTS.include?(endpoint) && ChefLicensing::Config.cache_enabled?
          perform_cache_first_operation(endpoint, params)
        else
          perform_default_operation(endpoint, params)
        end
      end

      # No application-level caching
      def perform_default_operation(endpoint, params = {})
        logger.debug "Fetching data from server for #{endpoint}"
        response = invoke_api(ChefLicensing::Config.license_server_url.split(","), endpoint, :get, nil, params)
        response.body
      end

      # Try to fetch data from application-cache first and if it fails, fallback to server
      def perform_cache_first_operation(endpoint, params = {})
        # Here, we do not iterate over multiple license server urls because
        # perform_api_fallback_operation will take care of that and update the license server url in config
        cache_key = @cache_manager.construct_cache_key(endpoint, params)
        logger.debug "Fetching data from cache for #{cache_key}"
        @cache_manager.fetch(cache_key) do
          logger.debug "Cache not found for #{cache_key}"
          logger.debug "Fetching data from server for #{cache_key}"
          response = invoke_api(ChefLicensing::Config.license_server_url.split(","), endpoint, :get, nil, params)
          # ttl_for_cache = @cache_manager.get_ttl_for_cache(response.body) # we receive cache expiration (and other cache info) from the response in the body
          logger.debug "Storing data in cache for #{cache_key}"
          @cache_manager.store(cache_key, response.body) if response.success? && response&.body&.status_code == 200
          response.body
        end
      end

      # Try to fetch data from the server first and if it fails, fallback to application-cache
      def perform_api_fallback_operation(endpoint, params = {})
        response = invoke_api(ChefLicensing::Config.license_server_url.split(","), endpoint, :get, nil, params)
        cache_key = @cache_manager.construct_cache_key(endpoint, params)
        logger.debug "Storing data in cache for #{cache_key}"
        # TODO: We don't receive cache info in the response body for listLicenses endpoint
        # so temporarily we are hardcoding the ttl to 46108 seconds (12 hours); check with the server team
        @cache_manager.store(cache_key, response.body, 46108) if response&.body&.status_code == 200 || response&.body&.status_code == 404
        response.body
      rescue RestfulClientConnectionError => e
        logger.debug "Restful Client Connection Error #{e.message}"
        logger.debug "Falling back to cache for #{endpoint}"
        cached_response = fetch_cache_with_fallback(endpoint, params)
        raise_restful_client_conn_error(ChefLicensing::Config.license_server_url.split(",")) if cached_response.nil?
        cached_response
      end

      def fetch_cache_with_fallback(endpoint, params = {})
        urls = ChefLicensing::Config.license_server_url.split(",")
        response = nil
        urls.each do |url|
          cache_key = @cache_manager.construct_cache_key(endpoint, params, url)
          logger.debug "Checking cache for #{cache_key}"
          if is_cached?(cache_key)
            logger.debug "Cache found for #{cache_key}"
            ChefLicensing::Config.license_server_url = url
            response = @cache_manager.fetch(cache_key)
            break
          end
        end
        response
      end

      # a common method to handle the post API calls
      def invoke_post_api(endpoint, payload, headers = {})
        response = invoke_api(ChefLicensing::Config.license_server_url.split(","), endpoint, :post, payload, nil, headers)
        raise RestfulClientError, format_error_from(response) unless response.success?

        response.body
      end

      def invoke_api(urls, endpoint, http_method, payload = nil, params = {}, headers = {})
        handle_connection = http_method == :get ? method(:handle_get_connection) : method(:handle_post_connection)
        response = nil
        attempted_urls = []

        logger.warn "Only the first #{REQUEST_LIMIT} urls will be tried." if urls.size > REQUEST_LIMIT
        urls.each_with_index do |url, i|
          url = url.strip
          attempted_urls << url
          break if i == REQUEST_LIMIT - 1

          logger.debug "Trying to connect to #{url}"
          handle_connection.call(url) do |connection|
            response = connection.send(http_method, endpoint) do |request|
              request.body = payload.to_json if payload
              request.params = params if params
              request.headers = headers if headers
            end
          end
          # At this point, we have a successful connection
          # Update the value of license server url in config
          ChefLicensing::Config.license_server_url = url
          logger.debug "Connection succeeded to #{url}"
          break response
        rescue RestfulClientConnectionError
          logger.warn "Connection failed to #{url}"
        rescue URI::InvalidURIError
          logger.warn "Invalid URI #{url}"
        end

        raise_restful_client_conn_error(attempted_urls) if response.nil?
        response
      end

      def handle_get_connection(url = nil)
        # handle faraday errors
        yield get_connection(url)
      rescue Faraday::ClientError => e
        logger.debug "Restful Client Error #{e.message}"
        raise RestfulClientError, e.message
      end

      def handle_post_connection(url = nil)
        # handle faraday errors
        yield post_connection(url)
      rescue Faraday::ClientError => e
        logger.debug "Restful Client Error #{e.message}"
        raise RestfulClientError, e.message
      end

      def get_connection(url = nil)
        store = ::ActiveSupport::Cache.lookup_store(:file_store, Dir.tmpdir)
        Faraday.new(url: url) do |config|
          config.request :json
          config.response :json, parser_options: { object_class: OpenStruct }
          config.use Faraday::HttpCache, shared_cache: false, logger: logger, store: store
          config.use Middleware::ExceptionsHandler
          config.adapter Faraday.default_adapter
        end
      end

      def post_connection(url = nil)
        Faraday.new(url: url) do |config|
          config.request :json
          config.response :json, parser_options: { object_class: OpenStruct }
          config.use Middleware::ExceptionsHandler
        end
      end

      def format_error_from(response)
        error_details = response.body&.data&.error
        return response.reason_phrase unless error_details

        error_details
      end

      def raise_restful_client_conn_error(urls)
        error_message = <<~EOM
          Unable to connect to the licensing server. #{ChefLicensing::Config.chef_product_name} requires server communication to operate.
          The following URL(s) were tried:\n#{
            urls.each_with_index.map do |url, index|
              "#{index + 1}. #{url}"
            end.join("\n")
          }
        EOM

        raise RestfulClientConnectionError, error_message
      end
    end
  end
end
