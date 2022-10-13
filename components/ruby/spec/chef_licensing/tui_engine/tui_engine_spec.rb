require "chef_licensing/tui_engine/tui_engine"
require "chef_licensing/license_key_validator"
require "chef_licensing/config"
require_relative "../../spec_helper"
require "stringio"
require "webmock/rspec"


RSpec.describe ChefLicensing::TUIEngine do
  describe "when a tui_engine object is instantiated with a valid yaml file" do

    context "when the yaml file has only single path at each interaction" do
      let(:config) {
        {
          output: STDOUT,
          input: STDIN,
          logger: Logger.new(STDOUT),
          yaml_file: File.join(File.dirname(__FILE__), "fixtures/basic_flow_with_one_path.yaml"),
        }
      }

      let(:tui_engine) { described_class.new(config) }

      it "should have a yaml_data object" do
        expect(tui_engine.yaml_data).to be_a(Hash)
      end

      it "should have a tui_interactions object" do
        expect(tui_engine.tui_interactions).to be_a(Hash)
      end

      it "should have a tui_interactions object with 4 interactions" do
        expect(tui_engine.tui_interactions.size).to eq(4)
      end

      it "should have a tui_interactions object with 4 interactions with the correct ids" do
        expect(tui_engine.tui_interactions.keys).to eq([:start, :prompt_2, :prompt_3, :exit])
      end
    end

    context "when the yaml file has multiple paths at each interaction" do
      # TODO: Add test for multiple paths
    end

    context "when the yaml file has no paths at each interaction" do
      # TODO: Add test for no paths
    end

    context "when the yaml file has no interactions" do
      # TODO: Add test for no interactions
    end

    context "when the yaml file has no yaml data" do
      # TODO: Add test for no yaml data
    end

    context "when the interaction has different types of prompts" do
      # TODO: Add test for different types of prompts
    end
  end

  describe "when a tui_engine object is instantiated with an invalid yaml file" do
    # TODO: Add test for invalid yaml file
  end

  describe "when a tui_engine object is instantiated with no input yaml file" do
    # TODO: Add test for no input yaml file
  end
end
