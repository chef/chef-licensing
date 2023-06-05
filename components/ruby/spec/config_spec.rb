require "chef-licensing/config"
require "logger"
require "stringio"
require "chef-licensing"

RSpec.describe ChefLicensing::Config do
  describe "#configure" do

    let(:output) { StringIO.new }
    let(:logger) { Logger.new(output) }

    context "when values are set via block" do
      before do
        ChefLicensing.configure do |config|
          config.logger = logger
          config.output = output
          config.license_server_url = "http://localhost-license-server/License"
          config.license_server_url_check_in_file = true
          config.air_gap_status = false
          config.chef_product_name = "inspec"
          config.chef_entitlement_id = "3ff52c37-e41f-4f6c-ad4d-365192205968"
          config.chef_executable_name = "inspec"
        end
      end

      it "sets the values" do
        expect(ChefLicensing::Config.license_server_url).to eq("http://localhost-license-server/License")
        expect(ChefLicensing::Config.logger).to eq(logger)
        expect(ChefLicensing::Config.output).to eq(output)
        expect(ChefLicensing::Config.air_gap_detected?).to eq(false)
        expect(ChefLicensing::Config.chef_product_name).to eq("inspec")
        expect(ChefLicensing::Config.chef_entitlement_id).to eq("3ff52c37-e41f-4f6c-ad4d-365192205968")
        expect(ChefLicensing::Config.chef_executable_name).to eq("inspec")
      end

      after do
        ChefLicensing.configure do |config|
          config.logger = nil
          config.output = nil
          config.license_server_url_check_in_file = false
          config.air_gap_status = nil
          config.chef_product_name = nil
          config.chef_entitlement_id = nil
          config.chef_executable_name = nil
        end
      end
    end

    context "fetching values from licenses.yaml file for license server url" do
      let(:opts) {
        {
          dir: "spec/fixtures/license_file_with_server_url",
        }
      }

      it "fetches the value from licenses.yaml file" do
        expect(ChefLicensing::Config.license_server_url(opts)).to eq("https://custom-licensing-server.com/License")
      end
    end
  end
end