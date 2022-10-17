require_relative "../license_key_validator"
require_relative "../exceptions/invalid_license"
module ChefLicensing
  class TUIEngine
    class TUIActions

      def initialize(opts = {}) end

      def validate_license_id(inputs)
        puts "Welcome you finally got here, atleast you are not a robot"
      end

      def is_license_valid?(inputs)
        # TODO: Match the regex after pulling and rebasing with main.
        license_id = inputs[:ask_for_license_id]
        puts "License validation in progress..."
        ChefLicensing::LicenseKeyValidator.validate!(license_id)
      rescue ChefLicensing::InvalidLicense => e
        # TODO: change warn to logger
        warn e.message
        false
      end
    end
  end
end
