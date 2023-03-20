require "chef-licensing/air_gap_detection/ping"
require_relative "../../spec_helper"

RSpec.describe ChefLicensing::AirGapDetection::Ping do

  describe "#detected?" do
    context "when the public licensing server is reachable" do
      let(:ping_air_gap) { described_class.new("https://localhost-license-server/License") }

      # Remember, "airgap disabled means online, reachable"
      # so ping detected? => false
      it "returns false" do
        stub_request(:get, "https://localhost-license-server/License/v1/version")
          .to_return(status: 200, body: '{"status_code":200,"version":"1"}')
        expect(ping_air_gap.detected?).to eq false
      end
    end

    context "when the public licensing server is not reachable" do
      let(:ping_air_gap) { described_class.new("https://wrong-url.co") }

      # Remember, "airgap detected means isolated, unreachable"
      # so ping detected? => true
      it "returns true" do
        stub_request(:get, "https://wrong-url.co/v1/version")
          .to_return(status: 404, body: "", headers: {})
        expect(ping_air_gap.detected?).to eq true
      end
    end
  end

end
