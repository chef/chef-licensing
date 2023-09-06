require "active_support/cache"
require "tmpdir" unless defined?(Dir.mktmpdir)
require_relative "../config"
require "digest" unless defined?(Digest)
require "active_support/time"

module ChefLicensing
  module RestfulClient
    class CacheManager
      attr_writer :default_ttl

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
        time_to_live ||= get_ttl_for_cache(data) || @default_ttl || 60
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

      # @param [String] endpoint: The endpoint to construct the cache key for
      # @param [Hash] params: The params to construct the cache key for
      # @param [String] license_server_url: The license server url to construct the cache key for
      # @return [String] The cache key
      def construct_cache_key(endpoint, params = {}, license_server_url = ChefLicensing::Config.license_server_url)
        string_to_hash = "#{license_server_url}_#{endpoint}"

        if params[:licenseId]
          license_id = params[:licenseId]

          # license_id is a comma separated string
          # we split it, sort it and join it back to make sure the cache key is consistent
          # for the same license ids in different order
          license_id = license_id.split(",").sort.join("")
          string_to_hash += "_#{license_id}"
        end

        if params[:entitlementId]
          string_to_hash += "_#{params[:entitlementId]}"
        end

        Digest::SHA256.hexdigest(string_to_hash)
      end

      private

      # @param [Object] response_data: The response data to fetch the cache expiration; response_data is the body of the response from the server
      #                 and the method expects to understand the structure of the response to fetch the cache expiration
      # @return [Integer] The cache expiration in seconds
      def get_ttl_for_cache(response_data)
        # Note: To make this method more generic, we can dig into the response_data and fetch the cache info
        if response_data.respond_to?(:data) && response_data.data.respond_to?(:cache)
          fetch_cache_expiration_from_cache_control(response_data.data.cache) || fetch_cache_expiration_from_expires(response_data.data.cache)
        end
      end

      # @param [Object] cache_info: The cache info to fetch the cache expiration; cache_info is the data received in the data.cache field
      # @return [Integer] The cache expiration in seconds
      def fetch_cache_expiration_from_cache_control(cache_info)
        cache_info.cacheControl.match(/max-age:(\d+)/)[1].to_i if cache_info.respond_to?(:cacheControl)
      end

      # @param [Object] cache_info: The cache info to fetch the cache expiration; cache_info is the data received in the data.cache field
      # @return [Integer] The cache expiration in seconds
      def fetch_cache_expiration_from_expires(cache_info)
        convert_timestamp_to_time_in_seconds(cache_info.expires) if cache_info.respond_to?(:expires)
      end

      # @param [String] timestamp: The timestamp to convert to time in seconds
      # @return [Integer] The time in seconds
      def convert_timestamp_to_time_in_seconds(timestamp)
        Time.zone = "UTC"
        expires_at = Time.zone.parse(timestamp)
        current_time = Time.zone.now
        (expires_at - current_time).to_i
      end
    end
  end
end
