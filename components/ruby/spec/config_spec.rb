require "chef-licensing/config"
require "logger"
require "stringio"
require "chef-licensing"

RSpec.describe ChefLicensing::Config do
  describe "#configure" do

    let(:output) { StringIO.new }
    let(:logger) { Logger.new(output) }

    context "default values" do
      it "has optional_mode set to false by default" do
        expect(ChefLicensing::Config.optional_mode).to eq(false)
      end
    end

    context "when values are set via block" do
      before do
        ChefLicensing.configure do |config|
          config.logger = logger
          config.output = output
          config.license_server_url = "http://localhost-license-server/License"
          config.license_server_url_check_in_file = true
          config.chef_product_name = "inspec"
          config.chef_entitlement_id = "3ff52c37-e41f-4f6c-ad4d-365192205968"
          config.chef_executable_name = "inspec"
        end
      end

      it "sets the values" do
        expect(ChefLicensing::Config.license_server_url).to eq("http://localhost-license-server/License")
        expect(ChefLicensing::Config.logger).to eq(logger)
        expect(ChefLicensing::Config.output).to eq(output)
        expect(ChefLicensing::Config.chef_product_name).to eq("inspec")
        expect(ChefLicensing::Config.chef_entitlement_id).to eq("3ff52c37-e41f-4f6c-ad4d-365192205968")
        expect(ChefLicensing::Config.chef_executable_name).to eq("inspec")
      end

      after do
        ChefLicensing.configure do |config|
          config.logger = nil
          config.output = nil
          config.license_server_url_check_in_file = false
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

    context "updating values in licenses.yaml file for license server url" do
      let(:temp_dir) { Dir.mktmpdir }
      let(:original_file) { "spec/fixtures/license_file_with_server_url/licenses.yaml" }

      before do
        FileUtils.cp(original_file, "#{temp_dir}/licenses.yaml")
        ChefLicensing.configure do |config|
          config.license_server_url_check_in_file = false
        end
      end

      let(:opts) {
        {
          dir: "#{temp_dir}",
        }
      }

      # add license server url to ARGV
      before do
        ARGV << "--chef-license-server" << "https://custom-licensing-server-2.com/License"
      end

      it "updates the value in licenses.yaml file" do
        # load the original file first and check the value
        expect(YAML.load_file("#{temp_dir}/licenses.yaml")[:license_server_url]).to eq("https://custom-licensing-server.com/License")
        # this will update the value in licenses.yaml file
        expect(ChefLicensing::Config.license_server_url(opts)).to eq("https://custom-licensing-server-2.com/License")
        # load the file again and check the value
        expect(YAML.load_file("#{temp_dir}/licenses.yaml")[:license_server_url]).to eq("https://custom-licensing-server-2.com/License")
      end

      after do
        ARGV.clear
      end
    end
  end
end