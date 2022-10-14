require "chef_licensing/air_gap/argument"
require "chef_licensing/air_gap"

RSpec.describe ChefLicensing::AirGap::Argument do
  let(:argv_air_gap) { described_class.new(argv) }

  describe "#enabled?" do
    context "when --airgap is enabled" do
      let(:argv) { ["--airgap"] }
      it "returns true" do
        expect(argv_air_gap.enabled?).to eq true
      end
    end

    context "when --airgap is not enabled" do
      let(:argv) { ["--no-airgap"] }
      it "returns false" do
        expect(argv_air_gap.enabled?).to eq false
      end
    end

    context "when --airgap is not present" do
      let(:argv) { [] }
      it "returns false" do
        expect(argv_air_gap.enabled?).to eq false
      end
    end
  end
end
