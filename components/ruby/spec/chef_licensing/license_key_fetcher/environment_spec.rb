require "spec_helper"
require "chef_licensing/license_key_fetcher/environment"
require "chef_licensing/license_key_fetcher"

RSpec.describe ChefLicensing::LicenseKeyFetcher::Environment do
  describe "#fetch" do

    describe "when the environment contains the correct key and value" do
      let(:env) { { "CHEF_LICENSE_KEY" => "12345678" } }
      it "fetches the license key" do
        env_fetcher = ChefLicensing::LicenseKeyFetcher::Environment.new(env)
        expect(env_fetcher.fetch).to eq(["12345678"])
      end
    end

    describe "when the environment contains wrong license key value" do
      let(:env) { { "CHEF_LICENSE_KEY" => "wrongkindoflicensekeyvalue" } }
      it "raises malformed error while fetching" do
        env_fetcher = ChefLicensing::LicenseKeyFetcher::Environment.new(env)
        expect { env_fetcher.fetch }.to raise_error(RuntimeError, /Malformed License Key passed in ENV variable CHEF_LICENSE_KEY - should be eight digits/)
      end
    end

    describe "when the environment contains empty license key value" do
      let(:env) { { "CHEF_LICENSE_KEY" => "" } }
      it "raises malformed error while fetching" do
        env_fetcher = ChefLicensing::LicenseKeyFetcher::Environment.new(env)
        expect { env_fetcher.fetch }.to raise_error(RuntimeError, /Malformed License Key passed in ENV variable CHEF_LICENSE_KEY - should be eight digits/)
      end
    end

    describe "when license key is not defined in env" do
      let(:env) { {} }
      it "returns nil" do
        env_fetcher = ChefLicensing::LicenseKeyFetcher::Environment.new(env)
        expect(env_fetcher.fetch).to eq(nil)
      end
    end
  end
end