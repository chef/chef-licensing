require "spec_helper"
require "chef-licensing/pstore_adapter"
require "chef-licensing/string_refinements"

RSpec.describe ChefLicensing::PStoreAdapter do
  let(:cache_dir) { Dir.mktmpdir }
  let(:adapter) { described_class.new(cache_dir) }

  after do
    FileUtils.rm_rf(cache_dir)
  end

  describe "#write and #read" do
    it "stores and retrieves values" do
      adapter.write("test_key", "test_value")
      expect(adapter.read("test_key")).to eq("test_value")
    end

    it "returns nil for non-existent keys" do
      expect(adapter.read("non_existent")).to be_nil
    end
  end

  describe "#exist?" do
    it "returns true for existing keys" do
      adapter.write("test_key", "test_value")
      expect(adapter.exist?("test_key")).to be true
    end

    it "returns false for non-existent keys" do
      expect(adapter.exist?("non_existent")).to be false
    end
  end

  describe "#delete" do
    it "removes cached values" do
      adapter.write("test_key", "test_value")
      adapter.delete("test_key")
      expect(adapter.read("test_key")).to be_nil
    end
  end

  describe "#clear" do
    it "removes all cached values" do
      adapter.write("key1", "value1")
      adapter.write("key2", "value2")
      adapter.clear
      expect(adapter.read("key1")).to be_nil
      expect(adapter.read("key2")).to be_nil
    end
  end
end

RSpec.describe ChefLicensing::PStoreAdapter do
  let(:cache_dir) { Dir.mktmpdir }
  let(:adapter) { described_class.new(cache_dir) }

  after do
    FileUtils.rm_rf(cache_dir)
  end

  it "provides the same interface as ActiveSupport::Cache" do
    adapter.write("test_key", "test_value")
    expect(adapter.read("test_key")).to eq("test_value")
    expect(adapter.exist?("test_key")).to be true

    adapter.delete("test_key")
    expect(adapter.read("test_key")).to be_nil
  end
end

RSpec.describe ChefLicensing::StringRefinements do
  using ChefLicensing::StringRefinements

  describe "#pluralize" do
    it "pluralizes regular words" do
      expect("Day".pluralize(2)).to eq("Days")
      expect("cat".pluralize(2)).to eq("cats")
    end

    it "handles words ending in s, sh, ch, x, z" do
      expect("class".pluralize(2)).to eq("classes")
      expect("dish".pluralize(2)).to eq("dishes")
      expect("church".pluralize(2)).to eq("churches")
      expect("box".pluralize(2)).to eq("boxes")
    end

    it "handles words ending in y" do
      expect("city".pluralize(2)).to eq("cities")
      expect("boy".pluralize(2)).to eq("boys") # vowel before y
    end

    it "handles words ending in f/fe" do
      expect("leaf".pluralize(2)).to eq("leaves")
      expect("knife".pluralize(2)).to eq("knives")
    end

    it "returns singular for count of 1" do
      expect("Day".pluralize(1)).to eq("Day")
      expect("cat".pluralize(1)).to eq("cat")
    end

    it "defaults to plural for no argument" do
      expect("Day".pluralize).to eq("Days")
    end
  end
end
