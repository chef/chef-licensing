require "pstore"

module ChefLicensing
  # Simple adapter to make PStore compatible with Faraday::HttpCache
  class PStoreAdapter
    def initialize(cache_dir)
      @store_path = File.join(cache_dir, "chef_licensing_cache.pstore")
      @store = PStore.new(@store_path)
    end

    # Interface methods required by faraday-http-cache
    def read(key)
      @store.transaction { @store[key] }
    end

    def write(key, value, options = {})
      # PStore handles persistence, Faraday::HttpCache handles
      # HTTP cache headers for expiration
      @store.transaction { @store[key] = value }
    end

    def delete(key)
      @store.transaction { @store.delete(key) }
    end

    def exist?(key)
      @store.transaction { @store.root?(key) }
    end

    def clear
      @store.transaction do
        @store.roots.each { |root| @store.delete(root) }
      end
    end
  end
end
