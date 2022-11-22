require "chef_licensing/config_fetcher/env_fetcher"

RSpec.describe ChefLicensing::EnvFetcher do

  let(:env_fetcher) { described_class.new(env) }

  describe "env_fetcher can fetch values in below formats" do

    context "when a boolean environment variable is passed" do
      let(:env) { { "CHEF_AIR_GAP" => "1" } }
      it "returns true if given environment variable is present" do
        expect(env_fetcher.fetch_value("CHEF_AIR_GAP", :boolean)).to eq true
      end
      it "returns false if given environment variable is not present" do
        expect(env_fetcher.fetch_value("CHEF_UNKNOWN", :boolean)).to eq false
      end
    end

    context "when a string environment variable is passed" do
      let(:env) { { "CHEF_LICENSE_SERVER" => "http://localhost:8080" } }
      it "returns the string value of given environment variable" do
        expect(env_fetcher.fetch_value("CHEF_LICENSE_SERVER", :string))
          .to eq "http://localhost:8080"
      end

      it "returns nil if given environment variable is not present" do
        expect(env_fetcher.fetch_value("CHEF_LICENSE_SERVER_API_KEY", :string)).to eq nil
      end
    end

    context "when no type is specified for an environment variable" do
      let(:env) { { "CHEF_LICENSE_SERVER" => "http://localhost:8080", "CHEF_LICENSE_SERVER_API_KEY" => "s0m3r4nd0mk3y" } }
      it "assumes the value is a string" do
        expect(env_fetcher.fetch_value("CHEF_LICENSE_SERVER")).to eq "http://localhost:8080"
        expect(env_fetcher.fetch_value("CHEF_LICENSE_SERVER_API_KEY")).to eq "s0m3r4nd0mk3y"
      end
    end
  end
end