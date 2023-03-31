require "chef-licensing/tui_engine/tui_prompt"
require "chef-licensing/tui_engine/tui_actions"
require "chef-licensing/tui_engine/tui_engine_state"
require "spec_helper"
require "chef-licensing"

RSpec.describe ChefLicensing::TUIEngine::TUIEngineState do

  let(:output) { StringIO.new }
  let(:logger) { Logger.new(output) }

  before do
    ChefLicensing.configure do |conf|
      conf.logger = logger
      conf.output = output
    end
  end

  let(:config) {
    {
      input: STDIN,
    }
  }

  let(:tui_engine_state) { described_class.new(config) }

  describe "when a tui_engine_state object is instantiated" do
    it "should have input field" do
      expect(tui_engine_state.input).to eq({ pastel: Pastel.new })
    end

    it "should have logger field" do
      expect(tui_engine_state.logger).to eq(logger)
    end

    it "should have prompt field" do
      expect(tui_engine_state.prompt).to be_a(ChefLicensing::TUIEngine::TUIPrompt)
    end

    it "should have tui_actions field" do
      expect(tui_engine_state.tui_actions).to be_a(ChefLicensing::TUIEngine::TUIActions)
    end

    it "should not have other fields" do
      expect { tui_engine_state.non_existing_field }.to raise_error(NoMethodError)
    end

    it "should respond to default_action method" do
      expect(tui_engine_state).to respond_to(:default_action)
    end
  end
end
