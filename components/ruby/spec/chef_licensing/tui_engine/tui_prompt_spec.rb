require "chef_licensing/tui_engine/tui_prompt"
require "chef_licensing/config"
require "spec_helper"

RSpec.describe ChefLicensing::TUIEngine::TUIPrompt do

  let(:opts) {
    {
      logger: Logger.new(StringIO.new),
    }
  }

  let(:cl_config) { ChefLicensing::Config.clone.instance(opts) }

  let(:config) {
    {
      output: STDOUT,
      input: STDIN,
      cl_config: cl_config,
    }
  }

  let(:tui_prompt) { described_class.new(config) }

  describe "when a tui_prompt object is instantiated" do
    it "should have output field" do
      expect(tui_prompt.output).to eq(STDOUT)
    end

    it "should have input field" do
      expect(tui_prompt.input).to eq(STDIN)
    end

    it "should have logger field" do
      expect(tui_prompt.logger).to eq(opts[:logger])
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
end
