require "chef_licensing/air_gap/argument"
require "chef_licensing/air_gap"

RSpec.describe ChefLicensing::AirGap::Argument do
  let(:acc) { described_class.new(argv) }

  describe "#verify_argv" do
    context "when --airgap is enabled" do
      let(:argv) { ["--airgap"] }
      it "returns true" do
        expect(acc.verify_argv).to eq true
      end
    end

    context "when --airgap is not enabled" do
      let(:argv) { ["--no-airgap"] }
      it "returns false" do
        expect(acc.verify_argv).to eq false
      end
    end
  end
end
