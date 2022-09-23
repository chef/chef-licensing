require "chef_licensing/air_gap/environment"
require "chef_licensing/air_gap"

RSpec.describe ChefLicensing::AirGap::Environment do
  let(:acc) { described_class.new(env) }
  
  describe "#verify_env" do
    context "when AIR_GAP is enabled" do
      let(:env) { {"AIR_GAP" => "enabled"} }
      it "raises an AirGapException" do
        expect { acc.verify_env }.to raise_error(ChefLicensing::AirGap::AirGapException, "AIR_GAP environment variable is enabled.")
      end
    end
    context "when AIR_GAP is not enabled" do
      let(:env) { {"AIR_GAP" => "disabled"} }
      it "does not raise an AirGapException" do
        expect { acc.verify_env }.not_to raise_error
      end
    end
  end
end