require "spec_helper"
require "chef_licensing/license_key_fetcher/environment"
require "chef_licensing/license_key_fetcher"

RSpec.describe ChefLicensing::LicenseKeyFetcher::Environment do
  describe "#fetch" do

    describe "when the environment contains the correct key and value" do
      let(:env) { { "CHEF_LICENSE_KEY" => "tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150" } }
      it "fetches the license key" do
        env_fetcher = ChefLicensing::LicenseKeyFetcher::Environment.new(env)
        expect(env_fetcher.fetch).to eq(["tmns-0f76efaf-b45b-4d92-86b2-2d144ce73dfa-150"])
      end
    end

    describe "when the environment contains wrong license key value" do
      let(:env) { { "CHEF_LICENSE_KEY" => "wrongkindoflicensekeyvalue" } }
      it "raises malformed error while fetching" do
        env_fetcher = ChefLicensing::LicenseKeyFetcher::Environment.new(env)
        expect { env_fetcher.fetch }.to raise_error(RuntimeError, /Malformed License Key passed in ENV variable CHEF_LICENSE_KEY/)
      end
    end

    describe "when the environment contains empty license key value" do
      let(:env) { { "CHEF_LICENSE_KEY" => "" } }
      it "raises malformed error while fetching" do
        env_fetcher = ChefLicensing::LicenseKeyFetcher::Environment.new(env)
        expect { env_fetcher.fetch }.to raise_error(RuntimeError, /Malformed License Key passed in ENV variable CHEF_LICENSE_KEY/)
      end
    end

    describe "when license key is not defined in env" do
      let(:env) { {} }
      it "returns an empty array" do
        env_fetcher = ChefLicensing::LicenseKeyFetcher::Environment.new(env)
        expect(env_fetcher.fetch).to eq([])
      end
    end
  end
end
