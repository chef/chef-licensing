require "chef_licensing/air_gap/environment"
require "chef_licensing/air_gap"

RSpec.describe ChefLicensing::AirGap::Environment do
  let(:env_air_gap) { described_class.new(env) }

  describe "#enabled?" do
    context "when AIR_GAP is enabled" do
      let(:env) { { "CHEF_AIR_GAP" => "enabled" } }
      it "returns true" do
        expect(env_air_gap.enabled?).to eq true
      end
    end

    context "when AIR_GAP is not enabled" do
      let(:env) { { "CHEF_AIR_GAP" => "disabled" } }
      it "returns false" do
        expect(env_air_gap.enabled?).to eq false
      end
    end
  end
end
