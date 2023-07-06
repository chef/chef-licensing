require "faraday" unless defined?(Faraday)
require "faraday/middleware"
require_relative "../../../chef-licensing/exceptions/restful_client_connection_error"

module Middleware
  # Middleware that handles the exception handler for chef licensing
  class ExceptionsHandler < Faraday::Middleware
    def call(env)
      @app.call(env)
    rescue Faraday::ConnectionFailed => e
      ChefLicensing::Config.logger.debug("Connection failed to #{ChefLicensing::Config.license_server_url} with error: #{e.message}")
      error_message = "Unable to connect to the licensing server at #{ChefLicensing::Config.license_server_url}.\nPlease check if the server is reachable and try again. #{ChefLicensing::Config.chef_product_name} requires server communication to operate."
      raise ChefLicensing::RestfulClientConnectionError, error_message
    end
  end
end
