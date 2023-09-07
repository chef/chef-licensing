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
      def fetch_from_server(endpoint, params = {})
        logger.debug "Fetching data from server for #{endpoint}"
        response = invoke_api(endpoint, :get, nil, params)
        response.body
      end

      def post_to_server(endpoint, payload = {}, headers = {})
        response = invoke_api(endpoint, :post, payload, nil, headers)
        raise RestfulClientError, format_error_from(response) unless response.success?

        response.body
      end

      # Try to fetch data from application-cache first and if it fails, fallback to server
      def fetch_from_cache_or_server(endpoint, params = {})
        cached_response = fetch_cached_response(endpoint, params)
        if cached_response.nil?
          logger.debug "Cache not found for #{endpoint}"
          logger.debug "Fetching data from server for #{endpoint}"
          response = invoke_api(endpoint, :get, nil, params)
          cache_key = @cache_manager.construct_cache_key(endpoint, params)
          logger.debug "Storing data in cache for #{cache_key}"
          @cache_manager.store(cache_key, response.body) if response.success? && response&.body&.status_code == 200
          response.body
        else
          logger.debug "Cache found for #{endpoint}"
          cached_response
        end
      end

      # Try to fetch data from the server first and if it fails, fallback to application-cache
      def fetch_from_server_or_cache(endpoint, params = {})
        response = invoke_api(endpoint, :get, nil, params)
        cache_key = @cache_manager.construct_cache_key(endpoint, params)
        logger.debug "Storing cache for #{endpoint}"
        # TODO: We don't receive cache info in the response body for listLicenses endpoint
        # so temporarily we are hardcoding the ttl to 46108 seconds (12 hours); check with the server team
        @cache_manager.store(cache_key, response.body, 46108) if response&.body&.status_code == 200 || response&.body&.status_code == 404
        response.body
      rescue RestfulClientConnectionError => e
        logger.debug "Restful Client Connection Error #{e.message}"
        logger.debug "Falling back to cache for #{endpoint}"
        cached_response = fetch_cached_response(endpoint, params)
        raise_restful_client_conn_error if cached_response.nil?
        cached_response
      end

      private

      attr_reader :cache_manager, :logger

      def fetch_cached_response(endpoint, params = {})
        urls = ChefLicensing::Config.license_server_url.split(",").first(REQUEST_LIMIT)
        response = nil
        urls.each do |url|
          cache_key = @cache_manager.construct_cache_key(endpoint, params, url)
          logger.debug "Checking cache for #{cache_key}"
          if @cache_manager.is_cached?(cache_key)
            logger.debug "Fetching data from cache for #{cache_key}"
            ChefLicensing::Config.license_server_url = url
            response = @cache_manager.fetch(cache_key)
            break
          end
        end
        response
      end

      def invoke_api(endpoint, http_method, payload = nil, params = {}, headers = {})
        response = nil
        urls = ChefLicensing::Config.license_server_url.split(",")

        logger.warn "Only the first #{REQUEST_LIMIT} urls will be tried." if urls.size > REQUEST_LIMIT
        urls.first(REQUEST_LIMIT).each do |url|
          url = url.strip

          logger.debug "Trying to connect to #{url}"

          response = @faraday_conn_handler.handle_connection(http_method, url) do |connection|
            connection.send(http_method, endpoint) do |request|
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

        raise_restful_client_conn_error if response.nil?
        response
      end

      def format_error_from(response)
        error_details = response.body&.data&.error
        return response.reason_phrase unless error_details

        error_details
      end

      def raise_restful_client_conn_error
        urls = ChefLicensing::Config.license_server_url.split(",").first(REQUEST_LIMIT)
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

