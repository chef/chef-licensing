require "chef-licensing/tui_engine/tui_actions"
require_relative "../../spec_helper"

RSpec.describe ChefLicensing::TUIEngine::TUIActions do
  let(:tui_actions) { described_class.new }

  describe "TUIActions class should exists" do
    it "should be a class" do
      expect(tui_actions).to be_a(ChefLicensing::TUIEngine::TUIActions)
    end
  end

  describe "#is_company_name_valid?" do
    valid_company_names = [
      "Chef Software",
      "InSpec",
      "Progress Softwares",
      "Company!!!",
      "Company 123",
      "Company&Co",
      "Company_123",
      "A Company",
      "A Company 123",
      "@ Company",
    ]

    valid_company_names.each do |company_name|
      it "should return true for valid company name '#{company_name}'" do
        expect(tui_actions.is_company_name_valid?({ gather_user_company_for_license_generation: company_name })).to be_truthy
      end
    end

    invalid_company_names = [
      "A", # too short
      "AB", # too short
      " A ", # leading space
      " ABC", # leading space
      "", # empty
      " ", # empty
      "A" * 21, # too long, max 20
    ]

    invalid_company_names.each do |company_name|
      it "should return false for invalid company name '#{company_name}'" do
        expect(tui_actions.is_company_name_valid?({ gather_user_company_for_license_generation: company_name })).to be_falsey
      end
    end

    unhandled_company_names = [
      "A  " # 3 characters, but by using space
    ]

    unhandled_company_names.each do |company_name|
      it "should return false but returns true for unhandled company name '#{company_name}'" do
        expect(tui_actions.is_company_name_valid?({ gather_user_company_for_license_generation: company_name })).to be_truthy
      end
    end
  end
end
