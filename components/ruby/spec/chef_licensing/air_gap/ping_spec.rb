require "chef_licensing/air_gap"
require "chef_licensing/air_gap/ping"
require_relative "../../spec_helper"

RSpec.describe ChefLicensing::AirGap::Ping do

  describe "#verify_ping" do
    context "when the public licensing server is reachable" do
      let(:acc) { described_class.new("https://licensing-acceptance.chef.co/") }

      it "returns false" do
        expect(acc.verify_ping).to eq true
      end
    end

    context "when the public licensing server is not reachable" do
      let(:acc) { described_class.new("https://wrong-url.co/") }

      it "returns true" do
        expect(acc.verify_ping).to eq false
      end
    end
  end

end
