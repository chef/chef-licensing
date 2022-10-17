require "spec_helper"
require_relative "../lib/chef_licensing"
require "logger"

RSpec.describe ChefLicensing do
  it "has a version number" do
    expect(ChefLicensing::VERSION).not_to be nil
  end

  describe ".configure" do
    let(:licensing_server) { "http://license-server" }
    let(:logger) { Logger.new($stdout) }
    before do
      described_class.configure { |c|
        c.licensing_server = "http://license-server"
        c.logger = logger
      }
    end

    it "is expected to update licensing server values" do
      expect(ChefLicensing::Config.licensing_server).to eq(licensing_server)
    end

    it "is expected to update logger values" do
      expect(ChefLicensing::Config.logger).to eq(logger)
    end
  end
end
