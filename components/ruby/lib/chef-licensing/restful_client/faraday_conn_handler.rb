
require "tmpdir" unless defined?(Dir.mktmpdir)
require "faraday" unless defined?(Faraday)
require "faraday/http_cache"
require "active_support"
require_relative "middleware/exceptions_handler"
require_relative "../exceptions/restful_client_error"
require_relative "../config"

module ChefLicensing
  module RestfulClient
    class FaradayConnHandler
      def initialize(opts = {})
        @logger = ChefLicensing::Config.logger
      end

      # @Usage:
      # faraday_conn_handler = ChefLicensing::RestfulClient::FaradayConnHandler.new
      # faraday_conn_handler.handle_connection(:get, server_url) do |conn|
      #  conn.get(endpoint) do |req|
      #    req.params = { "licenseId": "123" }
      #  end
      # end

      # faraday_conn_handler = ChefLicensing::RestfulClient::FaradayConnHandler.new
      # faraday_conn_handler.handle_connection(:post, server_url) do |conn|
      # conn.post(endpoint) do |req|
      #   req.body = { "licenseId": "123" }
      #   req.headers = { "Content-Type": "application/json" }
      # end
      # end

      # @param [Symbol] request_type: The request type to handle
      # @param [String] url: The url to connect to
      # @param [Block] block: The block to execute
      # @return [Object] The response body
      def handle_connection(request_type, url = nil, &block)
        if request_type == :get
          handle_get_connection(url, &block)
        elsif request_type == :post
          handle_post_connection(url, &block)
        else
          raise RestfulClientError, "Invalid request type #{request_type}"
        end
      end

      private

      attr_reader :logger

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
          config.use Faraday::HttpCache, shared_cache: false, logger: @logger, store: store
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
    end
  end
end
