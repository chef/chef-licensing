require_relative "cache_manager"
require_relative "../config"
require_relative "../exceptions/restful_client_error"
require_relative "../exceptions/restful_client_connection_error"
require_relative "faraday_conn_handler"

module ChefLicensing
  module RestfulClient
    class ApiGateway
      REQUEST_LIMIT = 5

      def initialize(opts = {})
        @cache_manager = opts[:cache_manager] || ChefLicensing::RestfulClient::CacheManager.new
        @logger = ChefLicensing::Config.logger
        @faraday_conn_handler = ChefLicensing::RestfulClient::FaradayConnHandler.new
      end

      # No application-level caching
      def perform_default_get_operation(endpoint, params = {})
        logger.debug "Fetching data from server for #{endpoint}"
        response = invoke_api(ChefLicensing::Config.license_server_url.split(","), endpoint, :get, nil, params)
        response.body
      end

      def perform_default_post_operation(endpoint, payload = {}, headers = {})
        response = invoke_api(ChefLicensing::Config.license_server_url.split(","), endpoint, :post, payload, nil, headers)
        raise RestfulClientError, format_error_from(response) unless response.success?

        response.body
      end

      # Try to fetch data from application-cache first and if it fails, fallback to server
      def perform_cache_first_get_operation(endpoint, params = {})
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
      def perform_api_first_get_operation(endpoint, params = {})
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

      private

      attr_reader :cache_manager, :logger

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

      def invoke_api(urls, endpoint, http_method, payload = nil, params = {}, headers = {})
        # get the connection from faraday connection handler object
        handle_connection = http_method == :get ? @faraday_conn_handler.method(:handle_get_connection) : @faraday_conn_handler.method(:handle_post_connection)
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

