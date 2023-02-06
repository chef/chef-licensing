require "chef_licensing/tui_engine/tui_actions"
require_relative "../../spec_helper"
require "chef_licensing/config"

RSpec.describe ChefLicensing::TUIEngine::TUIActions do

  let(:opts) {
    {
      logger: Logger.new(StringIO.new),
    }
  }

  let(:cl_config) {
    ChefLicensing::Config.clone.instance(opts)
  }

  let(:tui_actions) { described_class.new({ cl_config: cl_config }) }

  describe "TUIActions class should exists" do
    it "should be a class" do
      expect(tui_actions).to be_a(ChefLicensing::TUIEngine::TUIActions)
    end
  end
end
