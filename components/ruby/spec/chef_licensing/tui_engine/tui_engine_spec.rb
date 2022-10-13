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
          output: StringIO.new,
          input: StringIO.new,
          logger: Logger.new(StringIO.new),
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
        expect(tui_engine.tui_interactions.keys).to eq(%i{start prompt_2 prompt_3 exit})
      end

      it "should return processed_input as the interaction_id: nil hash" do
        expect(tui_engine.run_interaction).to eq({ start: nil, prompt_2: nil, prompt_3: nil, exit: nil })
      end
    end

    context "when the yaml file has multiple paths at each interaction and user selects Option 1" do
      # Here user presses enter to select Option 1
      let(:user_input) { StringIO.new }
      before do
        user_input.write("\n")
        user_input.rewind
      end

      let(:config) {
        {
          output: StringIO.new,
          input: user_input,
          logger: Logger.new(StringIO.new),
          yaml_file: File.join(File.dirname(__FILE__), "fixtures/flow_with_multiple_path_select.yaml"),
        }
      }

      let(:tui_engine) { described_class.new(config) }

      it "should have a tui_interactions object with 5 interactions" do
        expect(tui_engine.tui_interactions.size).to eq(5)
      end

      it "should have a tui_interactions object with 5 interactions with the correct ids" do
        expect(tui_engine.tui_interactions.keys).to eq(%i{start prompt_2 prompt_3 prompt_4 exit})
      end

      it "should return processed_input as the interaction_id: value hash but not prompt 4" do
        expect(tui_engine.run_interaction).to eq({ start: nil, prompt_2: "Option 1", prompt_3: nil, exit: nil })
      end
    end

    context "when the yaml file has multiple paths at each interaction and user selects Option 2" do
      # Here, user presses arrow down key to select Option 2 and then presses enter key to select it
      let(:user_input) { StringIO.new }
      before do
        user_input.write("\e[B\n")
        user_input.rewind
      end

      let(:config) {
        {
          output: StringIO.new,
          input: user_input,
          logger: Logger.new(StringIO.new),
          yaml_file: File.join(File.dirname(__FILE__), "fixtures/flow_with_multiple_path_select.yaml"),
        }
      }

      let(:tui_engine) { described_class.new(config) }

      it "should return processed_input as the interaction_id: value hash but not prompt 3" do
        expect(tui_engine.run_interaction).to eq({ start: nil, prompt_2: "Option 2", prompt_4: nil, exit: nil })
      end
    end

    context "when the yaml file has multiple paths at each interaction and user says yes" do
      # Here, user presses y key to select yes
      let(:user_input) { StringIO.new }
      before do
        user_input.write("y\nSome Input for ask prompt in prompt_6")
        user_input.rewind
      end

      let(:config) {
        {
          output: StringIO.new,
          input: user_input,
          logger: Logger.new(StringIO.new),
          yaml_file: File.join(File.dirname(__FILE__), "fixtures/flow_with_multiple_path_with_yes.yaml"),
        }
      }

      let(:tui_engine) { described_class.new(config) }

      it "should return processed_input as the interaction_id: value hash" do
        expect(tui_engine.run_interaction).to eq(
          {
            start: nil,
            prompt_2: true,
            prompt_3: ["This is message for prompt 3 - Reached when user says yes"],
            prompt_6: "Some Input for ask prompt in prompt_6",
            exit: nil,
          }
        )
      end
    end

    context "when the yaml file has multiple paths at each interaction and user says no" do
      # Here, user presses y key to select yes
      let(:user_input) { StringIO.new }
      before do
        user_input.write("n\n")
        user_input.rewind
      end

      let(:config) {
        {
          output: StringIO.new,
          input: user_input,
          logger: Logger.new(StringIO.new),
          yaml_file: File.join(File.dirname(__FILE__), "fixtures/flow_with_multiple_path_with_yes.yaml"),
        }
      }

      let(:tui_engine) { described_class.new(config) }

      it "should return processed_input as the interaction_id: value hash" do
        expect(tui_engine.run_interaction).to eq(
          {
            start: nil,
            prompt_2: false,
            prompt_4: ["This is message for prompt 4 - Reached when user says no"],
            prompt_5: ["This is message for prompt 5"],
            exit: nil,
          }
        )
      end
    end

    context "when the yaml file has no paths at each interaction" do
      let(:config) {
        {
          output: StringIO.new,
          input: StringIO.new,
          logger: Logger.new(StringIO.new),
          yaml_file: File.join(File.dirname(__FILE__), "fixtures/flow_with_no_path.yaml"),
        }
      }

      let(:tui_engine) { described_class.new(config) }

      it "should contain only the start interaction" do
        expect(tui_engine.run_interaction).to eq({ start: nil })
      end
    end

    context "when the yaml file is empty" do
      let(:config) {
        {
          output: StringIO.new,
          input: StringIO.new,
          logger: Logger.new(StringIO.new),
          yaml_file: File.join(File.dirname(__FILE__), "fixtures/flow_with_no_interaction.yaml"),
        }
      }

      it "should raise error while instantiating the class" do
        expect { described_class.new(config) }.to raise_error(ChefLicensing::TUIEngine::YAMLException)
      end
    end
  end

  describe "when a tui_engine object is instantiated with an invalid yaml file" do
    # TODO: Add test for invalid yaml file
  end

  describe "when a tui_engine object is instantiated with no input yaml file" do
    context "when the yaml file does not exists" do
      let(:config) {
        {
          output: StringIO.new,
          input: StringIO.new,
          logger: Logger.new(StringIO.new),
          yaml_file: File.join(File.dirname(__FILE__), "fixtures/unexisting_file.yaml"),
        }
      }

      it "should raise error while instantiating the class" do
        expect { described_class.new(config) }.to raise_error(ChefLicensing::TUIEngine::YAMLException)
      end
    end
  end
end
