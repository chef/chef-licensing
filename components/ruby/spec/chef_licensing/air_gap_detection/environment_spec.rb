require "chef_licensing/air_gap_detection/environment"
require "chef_licensing/air_gap_detection"

RSpec.describe ChefLicensing::AirGapDetection::Environment do
  let(:env_air_gap) { described_class.new(env) }

  describe "#detected?" do
    context "when CHEF_AIR_GAP is present" do
      let(:env) { { "CHEF_AIR_GAP" => "enabled" } }
      it "returns true" do
        expect(env_air_gap.detected?).to eq true
      end
    end

    context "when CHEF_AIR_GAP is not present" do
      let(:env) { { "CHEF_AIR_GAP" => "disabled" } }
      it "returns false" do
        expect(env_air_gap.detected?).to eq false
      end
    end
  end
end
