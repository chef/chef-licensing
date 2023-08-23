require "active_support/cache"
require "tmpdir" unless defined?(Dir.mktmpdir)
require_relative "../config"

module ChefLicensing
  module RestfulClient
    class CacheManager
      DEFAULT_TTL = 60
      def initialize(cache_dir = nil)
        @cache = ActiveSupport::Cache::FileStore.new(cache_dir || Dir.tmpdir)
        @logger = ChefLicensing::Config.logger
      end

      # @param [String] key: The key to fetch from the cache
      # @param [Block] block: The block to execute if the key is not cached
      # @return [Object] The cached data
      def fetch(key, &block)
        @logger.debug("CacheManager: Fetching #{key} from cache")
        @cache.fetch(key, &block)
      end

      # @param [String] key: The key to store in the cache
      # @param [Object] data: The data to store in the cache
      # @param [Integer] time_to_live: The time to live for the cached data - will be useful for testing
      # @return [Boolean] Whether the data is stored in the cache or not, true if stored
      def store(key, data, time_to_live = nil)
        @logger.debug("CacheManager: Storing #{key} in cache")
        time_to_live ||= DEFAULT_TTL
        options = { expires_in: time_to_live }
        @cache.write(key, data, options)
      end

      # @param [String] key: The key to delete from the cache
      # @return [Boolean/Nil] Whether the key is deleted or not; true if deleted, nil if key does not exist
      def delete(key)
        @logger.debug("CacheManager: Deleting #{key} from cache")
        @cache.delete(key)
      end

      # @param [String] key: The key to check in the cache
      # @return [Boolean] Whether the key is cached or not
      def is_cached?(key)
        @logger.debug("CacheManager: Checking if #{key} is cached")
        @cache.exist?(key)
      end
    end
  end
end
