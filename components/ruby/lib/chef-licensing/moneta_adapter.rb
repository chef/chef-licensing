require "moneta"

module ChefLicensing
  # Simple adapter to make Moneta compatible with Faraday::HttpCache
  class MonetaAdapter
    def initialize(cache_dir)
      @cache = Moneta.new(:File, dir: cache_dir, prefix: "chef_licensing_")
    end

    # Interface methods required by faraday-http-cache
    def read(key)
      @cache[key]
    end

    def write(key, value, options = {})
      # Moneta handles expiration differently, but for HTTP caching this is usually fine
      # as Faraday::HttpCache handles HTTP cache headers for expiration
      @cache[key] = value
    end

    def delete(key)
      @cache.delete(key)
    end

    def exist?(key)
      @cache.key?(key)
    end

    def clear
      @cache.clear
    end
  end
end
