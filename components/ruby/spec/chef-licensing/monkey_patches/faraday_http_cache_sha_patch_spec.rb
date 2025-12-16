require "spec_helper"
require "faraday"
require "faraday/http_cache/strategies/by_url"
require "chef-licensing/monkey_patches/faraday_http_cache_sha_patch"

RSpec.describe Faraday::HttpCache::Strategies::ByUrl do
  let(:strategy) { described_class.new }
  let(:url) { "https://example.com/api/resource" }

  it "generates a SHA256 cache key" do
    # Set the cache_salt instance variable to a known value
    strategy.instance_variable_set(:@cache_salt, "mysalt")
    expected = Digest::SHA256.hexdigest("mysalt#{url}")
    actual = strategy.send(:cache_key_for, url)
    expect(actual).to eq(expected)
    expect(actual.length).to eq(64) # SHA256 hex digest length
  end

  it "does not generate a SHA1 cache key" do
    strategy.instance_variable_set(:@cache_salt, "mysalt")
    sha1 = Digest::SHA1.hexdigest("mysalt#{url}")
    sha256 = strategy.send(:cache_key_for, url)
    expect(sha256).not_to eq(sha1)
    expect(sha256.length).to eq(64)
  end
end
