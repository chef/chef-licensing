require "chef_licensing/air_gap_detection/argument"
require "chef_licensing/air_gap_detection"

RSpec.describe ChefLicensing::AirGapDetection::Argument do
  let(:argv_air_gap) { described_class.new(argv) }

  describe "#detected?" do
    context "when --airgap is present" do
      let(:argv) { ["--airgap"] }
      it "returns true" do
        expect(argv_air_gap.detected?).to eq true
      end
    end

    context "when --no-airgap is present" do
      let(:argv) { ["--no-airgap"] }
      it "returns false" do
        expect(argv_air_gap.detected?).to eq false
      end
    end

    context "when --airgap is not present" do
      let(:argv) { [] }
      it "returns false" do
        expect(argv_air_gap.detected?).to eq false
      end
    end
  end
end
