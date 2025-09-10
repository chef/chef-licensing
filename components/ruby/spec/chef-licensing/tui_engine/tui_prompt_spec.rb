require "chef-licensing/tui_engine/tui_prompt"
require "spec_helper"
require "chef-licensing"
require "chef-licensing/tui_engine/tui_exceptions"

RSpec.describe ChefLicensing::TUIEngine::TUIPrompt do

  let(:output) { StringIO.new }
  let(:logger) {
    log = Object.new
    log.extend(Mixlib::Log)
    log.init(output)
    log
  }

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

  let(:tui_prompt) { described_class.new(config) }

  describe "when a tui_prompt object is instantiated" do
    it "should have output field" do
      expect(tui_prompt.output).to eq(output)
    end

    it "should have input field" do
      expect(tui_prompt.input).to eq(STDIN)
    end

    it "should have logger field" do
      expect(tui_prompt.logger).to eq(logger)
    end

    it "should have tty_prompt field" do
      expect(tui_prompt.tty_prompt).to be_a(TTY::Prompt)
    end

    it "should not have other fields" do
      expect { tui_prompt.non_existing_field }.to raise_error(NoMethodError)
    end

    it "should respond to yes method" do
      expect(tui_prompt).to respond_to(:yes)
    end

    it "should respond to say method" do
      expect(tui_prompt).to respond_to(:say)
    end

    it "should respond to ask method" do
      expect(tui_prompt).to respond_to(:ask)
    end

    it "should respond to select method" do
      expect(tui_prompt).to respond_to(:select)
    end

    it "should respond to enum_select method" do
      expect(tui_prompt).to respond_to(:enum_select)
    end
  end

  describe "when enum_select method is called with wrong arguments" do
    it "should raise an error" do
      expect { tui_prompt.enum_select("Single Message", {}) }.to raise_error(ChefLicensing::TUIEngine::BadPromptInput, /messages for enum_select must be an array of size greater than 1/)
    end
  end

  describe "when select method is called with wrong arguments" do
    it "should raise an error" do
      expect { tui_prompt.select("Single Message", {}) }.to raise_error(ChefLicensing::TUIEngine::BadPromptInput, /messages for select must be an array of size greater than 1/)
    end
  end
end
