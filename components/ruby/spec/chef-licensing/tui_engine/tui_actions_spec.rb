require "chef-licensing/tui_engine/tui_actions"
require_relative "../../spec_helper"

RSpec.describe ChefLicensing::TUIEngine::TUIActions do
  let(:tui_actions) { described_class.new }

  describe "TUIActions class should exists" do
    it "should be a class" do
      expect(tui_actions).to be_a(ChefLicensing::TUIEngine::TUIActions)
    end
  end
end
