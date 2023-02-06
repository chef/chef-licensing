require "chef_licensing/tui_engine/tui_engine"
require "chef_licensing/config"
require "spec_helper"
require "stringio"

RSpec.describe ChefLicensing::TUIEngine do
  let(:fixture_dir) { "spec/fixtures/tui_interactions" }

  let(:opts) {
    {
      logger: Logger.new(StringIO.new),
    }
  }

  let(:cl_config) { ChefLicensing::Config.clone.instance(opts) }

  describe "when a tui_engine object is instantiated with a valid yaml file" do

    context "when the yaml file has only single path at each interaction" do
      let(:config) {
        {
          output: StringIO.new,
          input: StringIO.new,
          interaction_file: File.join(fixture_dir, "basic_flow_with_one_path.yaml"),
          cl_config: cl_config,
        }
      }

      let(:tui_engine) { described_class.new(config) }

      it "should have a interaction_data object" do
        expect(tui_engine.interaction_data).to be_a(Hash)
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

      it "should return input as the interaction_id: nil hash" do
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
          interaction_file: File.join(fixture_dir, "flow_with_multiple_path_select.yaml"),
          cl_config: cl_config,
        }
      }

      let(:tui_engine) { described_class.new(config) }

      it "should have a tui_interactions object with 5 interactions" do
        expect(tui_engine.tui_interactions.size).to eq(5)
      end

      it "should have a tui_interactions object with 5 interactions with the correct ids" do
        expect(tui_engine.tui_interactions.keys).to eq(%i{start prompt_2 prompt_3 prompt_4 exit})
      end

      it "should return input as the interaction_id: value hash but not prompt 4" do
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
          interaction_file: File.join(fixture_dir, "flow_with_multiple_path_select.yaml"),
          cl_config: cl_config,
        }
      }

      let(:tui_engine) { described_class.new(config) }

      it "should return input as the interaction_id: value hash but not prompt 3" do
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
          interaction_file: File.join(fixture_dir, "flow_with_multiple_path_with_yes.yaml"),
          cl_config: cl_config,
        }
      }

      let(:tui_engine) { described_class.new(config) }

      it "should return input as the interaction_id: value hash" do
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
          interaction_file: File.join(fixture_dir, "flow_with_multiple_path_with_yes.yaml"),
          cl_config: cl_config,
        }
      }

      let(:tui_engine) { described_class.new(config) }

      it "should return input as the interaction_id: value hash" do
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
          interaction_file: File.join(fixture_dir, "flow_with_no_path.yaml"),
          cl_config: cl_config,
        }
      }

      let(:tui_engine) { described_class.new(config) }

      it "should raise exception of incomplete path" do
        expect { tui_engine.run_interaction }.to raise_error(ChefLicensing::TUIEngine::IncompleteFlowException, /Something went wrong in the flow./)
      end
    end

    context "when the yaml file has no interaction" do
      let(:config) {
        {
          output: StringIO.new,
          input: StringIO.new,
          interaction_file: File.join(fixture_dir, "flow_with_no_interaction.yaml"),
          cl_config: cl_config,
        }
      }

      it "should raise error while instantiating the class" do
        expect { described_class.new(config) }.to raise_error(ChefLicensing::TUIEngine::BadInteractionFile, /`interactions` key not found in yaml file./)
      end
    end

    context "when the interaction file has timeout_yes prompt" do
      let(:tui_output) { StringIO.new }

      let(:config) {
        {
          output: tui_output,
          # input: StringIO.new, # This is not required as we are not sending any input
          interaction_file: File.join(fixture_dir, "flow_with_timeout_yes.yaml"),
          cl_config: cl_config,
        }
      }

      let(:tui_engine) { described_class.new(config) }

      it "should timeout and exit in 1 second" do
        expect { tui_engine.run_interaction }.to raise_error(SystemExit)
        expect(tui_output.string).to include("Timed out!")
        expect(tui_output.string).to include("Oops! Reflex too slow.")
      end
    end

    context "when the interaction file has timeout_select prompt" do
      let(:tui_output) { StringIO.new }

      let(:config) {
        {
          output: tui_output,
          interaction_file: File.join(fixture_dir, "flow_with_timeout_select.yaml"),
          cl_config: cl_config,
        }
      }

      let(:tui_engine) { described_class.new(config) }

      it "should timeout and exit in 1 second" do
        expect { tui_engine.run_interaction }.to raise_error(SystemExit)
        expect(tui_output.string).to include("Timed out!")
        expect(tui_output.string).to include("Oops! Your reflex is too slow.")
      end
    end

    context "when the interaction file has messages in erb template" do
      let(:user_input) { StringIO.new }

      before do
        user_input.write("Chef User!\n")
        user_input.rewind
      end

      let(:config) {
        {
          output: StringIO.new,
          input: user_input,
          interaction_file: File.join(fixture_dir, "flow_with_erb_messages.yaml"),
          cl_config: cl_config,
        }
      }

      let(:tui_engine) { described_class.new(config) }

      it "should render the erb" do
        expect(tui_engine.run_interaction).to eq({ start: nil, ask_user_name: "Chef User!", welcome_user_in_english: ["Hello, Chef User!"], welcome_user_in_hindi: ["Namaste, Chef User!"], exit: nil })
      end
    end
    context "when the yaml file has an interaction without messages or action key" do
      let(:config) {
        {
          output: StringIO.new,
          input: StringIO.new,
          interaction_file: File.join(fixture_dir, "flow_without_messages_or_action.yaml"),
          cl_config: cl_config,
        }
      }

      it "should raise error while instantiating the class" do
        expect { described_class.new(config) }.to raise_error(ChefLicensing::TUIEngine::BadInteractionFile, /No action or messages found for interaction/)
      end
    end
  end

  describe "when a tui_engine object is instantiated with an invalid yaml file" do
    context "when interactions key is missing in yaml file" do
      let(:config) {
        {
          output: StringIO.new,
          input: StringIO.new,
          interaction_file: File.join(fixture_dir, "flow_with_missing_interactions_key.yaml"),
          cl_config: cl_config,
        }
      }
      it "should raise error while instantiating the class" do
        expect { described_class.new(config) }.to raise_error(ChefLicensing::TUIEngine::BadInteractionFile, /`interactions` key not found in yaml file./ )
      end
    end

    context "when interactions have some invalid key" do
      let(:config) {
        {
          output: StringIO.new,
          input: StringIO.new,
          interaction_file: File.join(fixture_dir, "flow_with_broken_keys.yaml"),
          cl_config: cl_config,
        }
      }

      before do
        @orig_stderr = $stderr
        $stderr = StringIO.new
      end

      it "warns about invalid key found in yaml file" do
        described_class.new(config)
        $stderr.rewind
        expect($stderr.string.chomp).to include("Invalid key `path` found in yaml file for interaction prompt_2")
        expect($stderr.string.chomp).to include("Invalid key `prompt_typr` found in yaml file for interaction start.")
        expect($stderr.string.chomp).to include("Valid keys are id, messages, action, prompt_type, prompt_attributes, response_path_map, paths, description")
      end

      after do
        $stderr = @orig_stderr
      end
    end

    context "when invalid value for prompt_type is given" do
      let(:config) {
        {
          output: StringIO.new,
          input: StringIO.new,
          interaction_file: File.join(fixture_dir, "flow_with_invalid_prompt_type.yaml"),
          cl_config: cl_config,
        }
      }

      it "raises error" do
        expect { described_class.new(config) }.to raise_error(ChefLicensing::TUIEngine::BadInteractionFile, /Invalid value `shout-type` for `prompt_type` key in yaml file for interaction/)
      end
    end

    context "when the yaml file is empty" do
      let(:config) {
        {
          output: StringIO.new,
          input: StringIO.new,
          interaction_file: File.join(fixture_dir, "empty_interaction_file.yaml"),
          cl_config: cl_config,
        }
      }

      it "should raise error while instantiating the class" do
        expect { described_class.new(config) }.to raise_error(ChefLicensing::TUIEngine::BadInteractionFile, /The interaction file has no data./)
      end
    end

    context "when the yaml file has no file_format_version" do
      let(:config) {
        {
          output: StringIO.new,
          input: StringIO.new,
          interaction_file: File.join(fixture_dir, "flow_with_no_file_format_version.yaml"),
          cl_config: cl_config,
        }
      }

      it "should raise error while instantiating the class" do
        expect { described_class.new(config) }.to raise_error(ChefLicensing::TUIEngine::BadInteractionFile, /`file_format_version` key not found in yaml file./)
      end
    end

    context "when the yaml file has invalid file_format_version" do
      let(:config) {
        {
          output: StringIO.new,
          input: StringIO.new,
          interaction_file: File.join(fixture_dir, "flow_with_invalid_file_format_version.yaml"),
          cl_config: cl_config,
        }
      }

      it "should raise error while instantiating the class" do
        expect { described_class.new(config) }.to raise_error(ChefLicensing::TUIEngine::UnsupportedInteractionFileFormat, /Unsupported interaction file format version./)
      end
    end
  end

  describe "when a tui_engine object is instantiated with no input yaml file" do
    context "when the yaml file does not exists" do
      let(:config) {
        {
          output: StringIO.new,
          input: StringIO.new,
          interaction_file: File.join(fixture_dir, "unexisting_file.yaml"),
          cl_config: cl_config,
        }
      }

      it "should raise error while instantiating the class" do
        expect { described_class.new(config) }.to raise_error(ChefLicensing::TUIEngine::BadInteractionFile, /Unable to load interaction file:/)
      end
    end

    context "when interaction file is not provided." do
      let(:config) {
        {
          output: StringIO.new,
          input: StringIO.new,
          cl_config: cl_config,
        }
      }

      it "should raise error while instantiating the class" do
        expect { described_class.new(config) }.to raise_error(
          ChefLicensing::TUIEngine::MissingInteractionFile, /No interaction file found. Please provide a valid file path to continue/
        )
      end
    end
  end
end
