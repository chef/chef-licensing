# require "chef_licensing/air_gap/argument"
require "chef_licensing/air_gap"

RSpec.describe ChefLicensing::AirGap::Argument do
  let(:acc) { described_class.new(argv) }
  
  describe "#verify_argv" do
    context "when --airgap is enabled" do
      let(:argv) { ["--airgap"] }
      it "raises an AirGapException" do
        expect { acc.verify_argv }.to raise_error(ChefLicensing::AirGap::AirGapException, "--airgap flag is enabled.")
      end
    end
    context "when --airgap is not enabled" do
      let(:argv) { ["--no-airgap"] }
      it "does not raise an AirGapException" do
        expect { acc.verify_argv }.not_to raise_error
      end
    end
  end
end