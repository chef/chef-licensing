require "chef_licensing/tui_engine/tui_engine"
require_relative "../../spec_helper"

RSpec.describe ChefLicensing::TUIEngine do
  describe "when a tui_engine object is instantiated" do
    context "with an external yaml file" do
      before do
        @pwd = Dir.pwd
        @file_path = File.join(@pwd, "chef_licensing/tui_engine/fixtures/tui-flow.yaml")
      end
      let(:tui_engine) { described_class.new(@file_path) }
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
end