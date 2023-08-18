require "spec_helper"

RSpec.describe ChefLicensing::RestfulClient::CacheManager do
  describe "#fetch" do
    Dir.mktmpdir do |dir|
      let(:cache_manager) { described_class.new(dir) }

      it "returns nil when the key is not cached" do
        expect(cache_manager.fetch("key")).to be_nil
      end

      it "returns the cached data when the key is cached with help of store" do
        cache_manager.store("key", "data")
        expect(cache_manager.fetch("key")).to eq("data")
      end

      it "executes the block when the key is not cached" do
        expect(cache_manager.fetch("key_2") { "Some code in this block" }).to eq("Some code in this block")
      end

      it "stores the data in the cache, returns data until TTL and then deletes" do
        cache_manager.store("key", "data", 2) # TTL of 2 seconds - TODO: Decide if we want to test the TTL functionality
        expect(cache_manager.fetch("key")).to eq("data")
        sleep 2 # wait for the TTL to expire
        expect(cache_manager.fetch("key")).to be_nil
      end
    end
  end

  describe "#store" do
    Dir.mktmpdir do |dir|
      let(:cache_manager) { described_class.new(dir) }
    end

    it "stores the data in the cache" do
      expect(cache_manager.store("key", "data")).to eq(true)
    end

    it "is able to store the data in the cache with a TTL parsed from the data" do
      # data is expected to be a response from the chef-licensing API and understands the structure to parse the TTL
      data = OpenStruct.new(data: OpenStruct.new(cache: OpenStruct.new(expires: "2020-01-01T00:00:00Z")))
      expect(cache_manager.store("key", data)).to eq(true)
    end
  end

  describe "#delete" do
    Dir.mktmpdir do |dir|
      let(:cache_manager) { described_class.new(dir) }

      it "deletes the key from the cache" do
        cache_manager.store("key", "data")
        expect(cache_manager.fetch("key")).to eq("data")
        cache_manager.delete("key")
        expect(cache_manager.fetch("key")).to be_nil
      end

      # TODO: Decide if we want to raise an error when the key is not cached
      it "does not raise an error when the key is not cached" do
        cache_manager.delete("key_2")
      end
    end
  end

  describe "#is_cached?" do
    Dir.mktmpdir do |dir|
      let(:cache_manager) { described_class.new(dir) }

      it "returns true when the key is cached" do
        cache_manager.store("key", "data")
        expect(cache_manager.is_cached?("key")).to eq(true)
      end

      it "returns false when the key is not cached" do
        expect(cache_manager.is_cached?("key_2")).to eq(false)
      end
    end
  end
end
