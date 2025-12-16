# Monkey patch for Faraday::HttpCache::Strategies::ByUrl to use SHA256 instead of SHA1 (FIPS compliant)
require "faraday" unless defined?(Faraday)
require "digest" unless defined?(Digest)
require "faraday/http_cache/strategies/by_url"

module Faraday
  class HttpCache < Faraday::Middleware
    module Strategies
      class ByUrl < BaseStrategy
        # Override the cache_key_for method to use SHA256
        def cache_key_for(url)
          Digest::SHA256.hexdigest("#{@cache_salt}#{url}")
        end
      end
    end
  end
end
