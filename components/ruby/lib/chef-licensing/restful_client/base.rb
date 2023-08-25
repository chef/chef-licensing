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

      CACHE_ENDPOINTS = [
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

      def generate_trial_license(payload)
        invoke_post_api(self.class::END_POINTS[:GENERATE_TRIAL_LICENSE], payload)
      end

      def generate_free_license(payload)
        invoke_post_api(self.class::END_POINTS[:GENERATE_FREE_LICENSE], payload)
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
        cache_key = construct_cache_key(endpoint, params)
        @cache_manager.delete(cache_key)
      end

      private

      attr_reader :logger

      # a common method to handle the get API calls
      def invoke_get_api(endpoint, params = {})
        if self.class::CACHE_ENDPOINTS.include?(endpoint) && ChefLicensing::Config.cache_enabled?
          cache_key = construct_cache_key(endpoint, params)
          logger.debug "Fetching data from cache for #{cache_key}"
          @cache_manager.fetch(cache_key) do
            logger.debug "Cache not found for #{cache_key}"
            logger.debug "Fetching data from server for #{cache_key}"
            response = invoke_api(ChefLicensing::Config.license_server_url.split(","), endpoint, :get, nil, params)
            ttl_for_cache = get_ttl_for_cache(response.body) # we receive cache expiration (and other cache info) from the response in the body
            logger.debug "Storing data in cache for #{cache_key}"
            @cache_manager.store(cache_key, response.body, ttl_for_cache) if response.success? && response&.body&.status_code == 200
            response.body
          end
        else
          # Current flow with no application-level caching
          response = invoke_api(ChefLicensing::Config.license_server_url.split(","), endpoint, :get, nil, params)
          response.body
        end
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

      def construct_cache_key(endpoint, params = {})
        string_to_hash = "#{ChefLicensing::Config.license_server_url}_#{endpoint}"

        if params[:licenseId]
          license_id = params[:licenseId]

          # license_id is a comma separated string
          # we split it, sort it and join it back to make sure the cache key is consistent
          # for the same license ids in different order
          license_id = license_id.split(",").sort.join("")
          string_to_hash += "_#{license_id}"
        end

        if params[:entitlementId]
          string_to_hash += "_#{params[:entitlementId]}"
        end

        Digest::SHA256.hexdigest(string_to_hash)
      end

      def get_ttl_for_cache(response_data)
        if response_data.respond_to?(:data) && response_data.data.respond_to?(:cache)
          fetch_cache_expiration_from_cache_control(response_data.data.cache) || fetch_cache_expiration_from_expires(response_data.data.cache)
        end
      end

      def fetch_cache_expiration_from_cache_control(cache_info)
        cache_info.cacheControl.match(/max-age:(\d+)/)[1].to_i if cache_info.respond_to?(:cacheControl)
      end

      def fetch_cache_expiration_from_expires(cache_info)
        convert_timestamp_to_time_in_seconds(cache_info.expires) if cache_info.respond_to?(:expires)
      end

      def convert_timestamp_to_time_in_seconds(timestamp)
        Time.zone = "UTC"
        expires_at = Time.zone.parse(timestamp)
        current_time = Time.zone.now
        (expires_at - current_time).to_i
      end
    end
  end
end
