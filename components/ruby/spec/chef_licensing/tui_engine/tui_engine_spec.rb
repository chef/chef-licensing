require "chef_licensing/tui_engine/tui_engine"
require_relative "../../spec_helper"
require "stringio"

RSpec.describe ChefLicensing::TUIEngine do
  describe "when a tui_engine object is instantiated" do
    context "with an external yaml file" do
      before do
        @pwd = Dir.pwd
        @file_path = File.join(@pwd, "chef_licensing/tui_engine/fixtures/tui-flow.yaml")
      end
      let(:config) { { yaml_file: @file_path } }
      let(:tui_engine) { described_class.new(config) }
      it "loads the yaml file data" do
        expect(tui_engine.yaml_data).to_not be_empty
      end

      it "creates tui_interaction objects" do
        expect(tui_engine.tui_interactions).to_not be_empty
        expect(tui_engine.tui_interactions).to be_a(Hash)
      end

      it "builds the interaction path" do
        expect(tui_engine.tui_interactions[:license_id_welcome_note].paths).to_not be_empty
        expect(tui_engine.tui_interactions[:license_id_welcome_note].paths).to be_a(Hash)
        expect(tui_engine.tui_interactions[:license_id_welcome_note].paths[:ask_if_user_has_license_id]).to be_a(ChefLicensing::TUIEngine::TUIInteraction)
      end
    end

    context "without any yaml file" do
      let(:tui_engine) { described_class.new }
      it "loads the default yaml file data" do
        expect(tui_engine.yaml_data).to_not be_empty
      end

      it "creates tui_interaction objects" do
        expect(tui_engine.tui_interactions).to_not be_empty
        expect(tui_engine.tui_interactions).to be_a(Hash)
      end
    end
  end

  describe "when a tui_engine object is invoked with run_interaction" do
    context "the user chooses to input license id and is a valid license id" do
      let(:input) { StringIO.new }
      before do
        input.write("yes\n12345678")
        input.rewind
      end
      let(:output) { StringIO.new }
      let(:config) { { input: input, output: output } }
      let(:tui_engine) { described_class.new(config) }
      it "returns a hash of user input and the validity of license id" do
        expect(tui_engine.run_interaction).to eq({ answer: true, license_id: "12345678", license_id_valid: true })
      end
    end

    context "the user chooses to input license id and is not a valid license id" do
      let(:input) { StringIO.new }
      before do
        input.write("yes\n98765432")
        input.rewind
      end
      let(:output) { StringIO.new }
      let(:config) { { input: input, output: output } }
      let(:tui_engine) { described_class.new(config) }
      it "returns a hash of user input and the validity of license id" do
        # TODO: Uncomment the below line after adding the license id validation logic in tui engine state
        # expect(tui_engine.run_interaction).to eq({ answer: true, license_id: "12345678", license_id_valid: false })
      end
    end
  end
end