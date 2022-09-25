require "chef_licensing/air_gap"
require "chef_licensing/air_gap/ping"
require_relative "../../spec_helper"

RSpec.describe ChefLicensing::AirGap::Ping do

  describe "#verify_ping" do
    context "when the public licensing server is reachable" do
      let(:acc) { described_class.new("https://licensing-acceptance.chef.co/") }

      it "does not raise an AirGapException" do
        expect { acc.verify_ping }.not_to raise_error
      end
    end

    context "when the public licensing server is not reachable" do
      let(:acc) { described_class.new("https://wrong-url.co/") }

      it "does not raise an AirGapException" do
        expect { acc.verify_ping }.to raise_error
      end
    end
  end

end
