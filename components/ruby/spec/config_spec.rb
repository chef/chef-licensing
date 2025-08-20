require "chef-licensing/config"
require "logger"
require "stringio"
require "chef-licensing"

RSpec.describe ChefLicensing::Config do
  describe "#configure" do

    let(:output) { StringIO.new }
    let(:logger) { Logger.new(output) }

    context "default values" do
      it "has make_licensing_optional set to false by default" do
        expect(ChefLicensing::Config.make_licensing_optional).to eq(false)
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

  describe "#require_license_for" do
    before do
      # Mock fetch_and_persist to prevent actual license fetching during tests
      allow(ChefLicensing).to receive(:fetch_and_persist)
    end

    context "when make_licensing_optional is initially true" do
      before do
        ChefLicensing::Config.make_licensing_optional = true
      end

      it "temporarily sets make_licensing_optional to false within the block" do
        expect(ChefLicensing::Config.make_licensing_optional).to eq(true)

        ChefLicensing::Config.require_license_for do
          expect(ChefLicensing::Config.make_licensing_optional).to eq(false)
        end

        expect(ChefLicensing::Config.make_licensing_optional).to eq(true)
      end

      it "calls fetch_and_persist before executing the block" do
        expect(ChefLicensing).to receive(:fetch_and_persist).once

        ChefLicensing::Config.require_license_for do
          # block content
        end
      end

      it "restores original value even when block raises an exception" do
        expect(ChefLicensing::Config.make_licensing_optional).to eq(true)

        expect {
          ChefLicensing::Config.require_license_for do
            expect(ChefLicensing::Config.make_licensing_optional).to eq(false)
            raise StandardError, "test exception"
          end
        }.to raise_error(StandardError, "test exception")

        expect(ChefLicensing::Config.make_licensing_optional).to eq(true)
      end

      it "restores original value even when fetch_and_persist raises an exception" do
        allow(ChefLicensing).to receive(:fetch_and_persist).and_raise(StandardError, "fetch error")
        expect(ChefLicensing::Config.make_licensing_optional).to eq(true)

        expect {
          ChefLicensing::Config.require_license_for do
            # block content
          end
        }.to raise_error(StandardError, "fetch error")

        expect(ChefLicensing::Config.make_licensing_optional).to eq(true)
      end

      it "is thread-safe when called concurrently" do
        results = []
        threads = []

        # Create multiple threads that call require_license_for concurrently
        5.times do |i|
          threads << Thread.new do
            ChefLicensing::Config.require_license_for do
              sleep(0.01) # Small delay to increase chance of race conditions
              results << ChefLicensing::Config.make_licensing_optional
            end
          end
        end

        # Wait for all threads to complete
        threads.each(&:join)

        # All threads should see make_licensing_optional as false during execution
        expect(results).to all(eq(false))

        # After all threads complete, original value should be restored
        expect(ChefLicensing::Config.make_licensing_optional).to eq(true)
      end
    end

    context "when make_licensing_optional is initially false" do
      before do
        ChefLicensing::Config.make_licensing_optional = false
      end

      it "keeps make_licensing_optional as false within the block and restores afterward" do
        expect(ChefLicensing::Config.make_licensing_optional).to eq(false)

        ChefLicensing::Config.require_license_for do
          expect(ChefLicensing::Config.make_licensing_optional).to eq(false)
        end

        expect(ChefLicensing::Config.make_licensing_optional).to eq(false)
      end

      it "calls fetch_and_persist before executing the block" do
        expect(ChefLicensing).to receive(:fetch_and_persist).once

        ChefLicensing::Config.require_license_for do
          # block content
        end
      end
    end

    context "when no block is given" do
      it "returns nil and does not affect make_licensing_optional" do
        ChefLicensing::Config.make_licensing_optional = true

        result = ChefLicensing::Config.require_license_for

        expect(result).to be_nil
        expect(ChefLicensing::Config.make_licensing_optional).to eq(true)
      end

      it "does not call fetch_and_persist when no block is given" do
        expect(ChefLicensing).not_to receive(:fetch_and_persist)

        ChefLicensing::Config.require_license_for
      end
    end

    context "when block returns a value" do
      before do
        ChefLicensing::Config.make_licensing_optional = true
      end

      it "returns the block's return value" do
        result = ChefLicensing::Config.require_license_for do
          "block return value"
        end

        expect(result).to eq("block return value")
        expect(ChefLicensing::Config.make_licensing_optional).to eq(true)
      end

      it "calls fetch_and_persist before executing the block" do
        expect(ChefLicensing).to receive(:fetch_and_persist).once

        ChefLicensing::Config.require_license_for do
          "block return value"
        end
      end
    end

    after do
      # Reset to default value after each test
      ChefLicensing::Config.make_licensing_optional = false
    end
  end
end