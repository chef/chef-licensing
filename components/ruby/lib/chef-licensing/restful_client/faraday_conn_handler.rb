
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

      private

      attr_reader :logger

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
