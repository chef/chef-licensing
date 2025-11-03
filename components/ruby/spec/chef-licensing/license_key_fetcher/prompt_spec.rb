require "tty-prompt"
require "chef-licensing/license_key_fetcher/prompt"
require "logger"

RSpec.describe ChefLicensing::LicenseKeyFetcher::Prompt do
  let(:output) { StringIO.new }
  let(:logger) {
    log = Object.new
    log.extend(Mixlib::Log)
    log.init(output)
    log
  }

  describe "when the user chooses to input license id" do
    # TODO: Implement this test
    it "should do something" do
    end
  end

  describe "when the user chooses to generate a license id" do
    # TODO: Implement this test
    it "should do something" do
    end
  end

  describe "when the user chooses to exit" do
    # TODO: Implement this test
    it "should do something" do
    end
  end
end
