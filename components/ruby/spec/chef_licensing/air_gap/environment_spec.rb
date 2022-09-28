require "chef_licensing/air_gap/environment"
require "chef_licensing/air_gap"

RSpec.describe ChefLicensing::AirGap::Environment do
  let(:acc) { described_class.new(env) }

  describe "#verify_env" do
    context "when AIR_GAP is enabled" do
      let(:env) { { "AIR_GAP" => "enabled" } }
      it "returns true" do
        expect(acc.verify_env).to eq true
      end
    end

    context "when AIR_GAP is not enabled" do
      let(:env) { { "AIR_GAP" => "disabled" } }
      it "returns false" do
        expect(acc.verify_env).to eq false
      end
    end
  end
end
