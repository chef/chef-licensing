require "chef_licensing/tui_engine/tui_interaction"
require_relative "../../spec_helper"

RSpec.describe ChefLicensing::TUIEngine::TUIInteraction do

  let(:config) {
    {
    messages: ["test"],
    action: "some_action",
  }
  }
  let(:tui_interaction) { described_class.new(config) }

  describe "when a tui_interaction object is instantiated" do
    it "should have messages field" do
      expect(tui_interaction.messages).to eq(["test"])
    end

    it "should have an action field" do
      expect(tui_interaction.action).to eq("some_action")
    end

    it "should have paths field" do
      expect(tui_interaction.paths).to eq({})
    end

    it "should not have other fields" do
      expect { tui_interaction.non_existing_field }.to raise_error
    end
  end
end
