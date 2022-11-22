require "chef_licensing/config_fetcher/arg_fetcher"

RSpec.describe ChefLicensing::ArgFetcher do

  let(:arg_fetcher) { described_class.new(argv) }

  describe "arg_fetcher can fetch values in below formats" do

    context "when a boolean argument is passed" do
      let(:argv) { ["--airgap"] }
      it "returns true if given argument is present" do
        expect(arg_fetcher.fetch_value("--airgap", :boolean)).to eq true
      end

      it "returns false if given argument is not present" do
        expect(arg_fetcher.fetch_value("--no-airgap", :boolean)).to eq false
      end
    end

    context "when a string argument is passed as --arg_name arg_value" do
      let(:argv) { ["--chef-license-server", "http://localhost:8080"] }
      it "returns the string value of given argument" do
        expect(arg_fetcher.fetch_value("--chef-license-server", :string)).to eq "http://localhost:8080"
      end

      it "returns nil if given argument is not present" do
        expect(arg_fetcher.fetch_value("--chef-license-server-api-key", :string)).to eq nil
      end
    end

    context "when a string argument is passed as --arg_name=arg_value" do
      let(:argv) { ["--chef-license-server=http://localhost:8080"] }
      it "returns the string value of given argument" do
        expect(arg_fetcher.fetch_value("--chef-license-server", :string)).to eq "http://localhost:8080"
      end

      it "returns nil if given argument is not present" do
        expect(arg_fetcher.fetch_value("--chef-license-server-api-key", :string)).to eq nil
      end
    end
  end

  describe "arg_fetcher cannot fetch multiple values for same argument" do
    let(:argv) { ["--chef-license-license-key", "s0m3dummyk3y", "4n0th3rdumm1yk3y"] }
    it "returns the first value of given argument" do
      expect(arg_fetcher.fetch_value("--chef-license-license-key", :string)).to eq "s0m3dummyk3y"
    end

    it "cannot return the second value of given argument" do
      expect(arg_fetcher.fetch_value("--chef-license-license-key", :string)).to_not eq "4n0th3rdumm1yk3y"
    end
  end
end