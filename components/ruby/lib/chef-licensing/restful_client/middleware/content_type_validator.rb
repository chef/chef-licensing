require "faraday/middleware"
require_relative "../../../chef-licensing/exceptions/unsupported_content_type"

module Middleware
  class ContentTypeValidator < Faraday::Middleware
    def call(env)
      @app.call(env).on_complete do |response_env|
        content_type = response_env[:response_headers]["content-type"]
        body = response_env[:body]
        # trim the body to 1000 characters to avoid printing a huge string in the error message
        body = body[0..1000] if body.is_a?(String)
        raise ChefLicensing::UnsupportedContentType, error_message(content_type, body) unless content_type == "application/json"
      end
    end

    def error_message(content_type, body = nil)
      <<~EOM
        Expected 'application/json' content-type, but received '#{content_type}' from the licensing server.
        Snippet of body: `#{body}`
        Possible causes: Check for firewall restrictions, ensure proper server response, or seek support assistance.
      EOM
    end
  end
end
