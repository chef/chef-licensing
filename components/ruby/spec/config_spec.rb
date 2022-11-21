require "chef_licensing/config"

RSpec.describe ChefLicensing::Config do

  describe "test config with given values" do
    let(:opts_1) {
      {
        cli_args: ["--airgap", "--chef-license-server-api-key", "s0m3r4nd0m4p1k3y"],
        env_vars: {
          "CHEF_LICENSE_SERVER" => "https://license.chef.io",
        },
        logger: Logger.new(STDERR),
      }
    }

    let(:opts_2) {
      {
        cli_args: ["--airgap", "--chef-license-server-api-key", "4n0th3r4p1k3y"],
        env_vars: {
          "CHEF_LICENSE_SERVER" => "https://license.progress.io",
        },
        logger: Logger.new(STDERR),
      }
    }

    let(:instance_1) { ChefLicensing::Config.clone.instance(opts_1) }

    let(:instance_2) { ChefLicensing::Config.clone.instance(opts_2) }

    it "should not be the same instance" do
      expect(instance_1).not_to be(instance_2)
    end

    it "should have different values" do
      expect(instance_1.license_server_url).not_to eq(instance_2.license_server_url)
      expect(instance_1.license_server_api_key).not_to eq(instance_2.license_server_api_key)
    end

    it "should give the correct values" do
      expect(instance_1.license_server_url).to eq("https://license.chef.io")
      expect(instance_1.license_server_api_key).to eq("s0m3r4nd0m4p1k3y")
      expect(instance_2.license_server_url).to eq("https://license.progress.io")
      expect(instance_2.license_server_api_key).to eq("4n0th3r4p1k3y")
    end
  end

  after do
    ChefLicensing::Config.reset!
  end
end