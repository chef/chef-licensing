require "chef_licensing/tui_engine/tui_engine"
require "chef_licensing/license_key_validator"
require "chef_licensing/config"
require_relative "../../spec_helper"
require "stringio"
require "webmock/rspec"


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
        input.write("yes\ntmns-90564f0a-ad22-482f-b57d-569f3fb1c11e-6620")
        input.rewind

        stub_request(:get, "#{ChefLicensing::Config::LICENSING_SERVER}/v1/validate")
        .with(query: { licenseId: "tmns-90564f0a-ad22-482f-b57d-569f3fb1c11e-6620" })
        .to_return(body: { data: true, message: "License Id is valid", status_code: 200 }.to_json,
                  headers: { content_type: "application/json" })
      end

      let(:output) { StringIO.new }
      let(:config) { { input: input, output: output } }
      let(:tui_engine) { described_class.new(config) }
      it "returns a hash of user input and the validity of license id" do
        expect(tui_engine.run_interaction).to eq({ answer: true, license_id: "tmns-90564f0a-ad22-482f-b57d-569f3fb1c11e-6620", license_id_valid: true })
      end
    end
  end
end
