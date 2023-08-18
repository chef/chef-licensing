require "active_support/cache"
require "time" unless defined?(Time.zone_offset)
require "tmpdir" unless defined?(Dir.mktmpdir)

module ChefLicensing
  module RestfulClient
    class CacheManager
      DEFAULT_TTL = 60
      def initialize(cache_dir = nil)
        @cache = ActiveSupport::Cache::FileStore.new(cache_dir || Dir.tmpdir)
      end

      # @param [String] key: The key to fetch from the cache
      # @param [Block] block: The block to execute if the key is not cached
      # @return [Object] The cached data
      def fetch(key, &block)
        @cache.fetch(key, &block)
      end

      # @param [String] key: The key to store in the cache
      # @param [Object] data: The data to store in the cache
      # @param [Integer] time_to_live: The time to live for the cached data - will be useful for testing
      # @return [void]
      def store(key, data, time_to_live = nil)
        time_to_live ||= calculate_time_to_live(data)
        options = { expires_in: time_to_live }
        @cache.write(key, data, options)
      end

      # @param [String] key: The key to delete from the cache
      # @return [void]
      def delete(key)
        @cache.delete(key)
      end

      # @param [String] key: The key to check in the cache
      # @return [Boolean] Whether the key is cached or not
      def is_cached?(key)
        @cache.exist?(key)
      end

      private

      # @param [Object] data: The data to find the time to live
      # @return [Integer] The time to live for the cached data
      def calculate_time_to_live(data)
        if cache_expiration_available?(data)
          calculate_time_to_live_from_expiration(data.data.cache.expires)
        else
          DEFAULT_TTL
        end
      end

      # @param [Object] data: The data to check if it has cache expiration
      # @return [Boolean] Whether the data has cache expiration or not
      # @note: This method assumes that the data is a response from the chef-licensing API and understands the structure
      def cache_expiration_available?(data)
        data.respond_to?(:data) && data.data.respond_to?(:cache) && data.data.cache.respond_to?(:expires)
      end

      # @param [String] expiration_timestamp: The timestamp to calculate time to live
      # @return [Integer] The time to live for the cached data
      def calculate_time_to_live_from_expiration(expiration_timestamp)
        current_time = Time.now.utc
        expires_at = Time.parse(expiration_timestamp)
        (expires_at - current_time).to_i
      end
    end
  end
end
