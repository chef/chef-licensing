# frozen_string_literal: true

require "faraday" unless defined?(Faraday)
require "faraday/middleware"
require_relative "../../../chef-licensing/exceptions/restful_client_error"

module Middleware
  class ExceptionsHandler < Faraday::Middleware
    def call(env)
      @app.call(env)
    rescue Faraday::ConnectionFailed => e
      raise ChefLicensing::RestfulClientError, "Connection to License Server failed"
    end
  end
end
