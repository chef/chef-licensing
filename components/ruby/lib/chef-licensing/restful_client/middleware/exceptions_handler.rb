require "faraday" unless defined?(Faraday)
require "faraday/middleware"
require_relative "../../../chef-licensing/exceptions/restful_client_connection_error"

module Middleware
  # Middleware that handles the exception handler for chef licensing
  class ExceptionsHandler < Faraday::Middleware
    def call(env)
      @app.call(env)
    rescue Faraday::ConnectionFailed => e
      raise ChefLicensing::RestfulClientConnectionError, e.message
    end
  end
end
