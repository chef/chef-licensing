require "chef-licensing/config"
require "logger"
require "chef-licensing"
require "spec_helper"
require "stringio"
require "fileutils" unless defined?(FileUtils)

RSpec.describe ChefLicensing::Config do
  describe "#configure" do

    let(:output) { StringIO.new }
    let(:logger) { Logger.new(output) }

    context "when values are set via block" do
      it "sets the values" do

        ChefLicensing.configure do |config|
          config.logger = logger
          config.output = output
          config.license_server_url = "http://localhost-license-server/License"
          config.air_gap_status = false
          config.chef_product_name = "inspec"
          config.chef_entitlement_id = "3ff52c37-e41f-4f6c-ad4d-365192205968"
          config.chef_executable_name = "inspec"
        end

        expect(ChefLicensing::Config.license_server_url).to eq("http://localhost-license-server/License")
        expect(ChefLicensing::Config.logger).to eq(logger)
        expect(ChefLicensing::Config.output).to eq(output)
        expect(ChefLicensing::Config.air_gap_detected?).to eq(false)
        expect(ChefLicensing::Config.chef_product_name).to eq("inspec")
        expect(ChefLicensing::Config.chef_entitlement_id).to eq("3ff52c37-e41f-4f6c-ad4d-365192205968")
        expect(ChefLicensing::Config.chef_executable_name).to eq("inspec")
      end
    end

    context "when values are set via environment variables" do
    end

    context "when values are set via command line arguments" do
    end

    context "fetching values from licenses.yaml file for license server url" do
    end
  end
end