require "chef_licensing/tui_engine/tui_interaction"
require_relative "../../spec_helper"

RSpec.describe ChefLicensing::TUIEngine::TUIInteraction do

  let(:config) {
    {
      id: :start,
      messages: ["This is a test message!"],
      prompt_type: "say",
      response_path_map: { "This is a test message!" => "some_next_identifier" },
      action: "some_action",
    }
  }

  let(:tui_interaction) { described_class.new(config) }

  describe "when a tui_interaction object is instantiated" do
    it "should have id field" do
      expect(tui_interaction.id).to eq(:start)
    end

    it "should have messages field" do
      expect(tui_interaction.messages).to eq(["This is a test message!"])
    end

    it "should have an action field" do
      expect(tui_interaction.action).to eq("some_action")
    end

    it "should have a prompt_type field" do
      expect(tui_interaction.prompt_type).to eq("say")
    end

    it "should have a response_path_map field" do
      expect(tui_interaction.response_path_map).to eq({ "This is a test message!" => "some_next_identifier" })
    end

    it "should have paths field" do
      expect(tui_interaction.paths).to eq({})
    end

    it "should not have other fields" do
      expect { tui_interaction.non_existing_field }.to raise_error
    end
  end
end
