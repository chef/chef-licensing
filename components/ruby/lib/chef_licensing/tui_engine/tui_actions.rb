require_relative "../license_key_validator"
require_relative "../exceptions/invalid_license"
require_relative "../license_key_fetcher/base"
module ChefLicensing
  class TUIEngine
    # TODO: Is there a better way to use the base class?
    # Base class is required for constants like LICENSE_KEY_REGEX
    class TUIActions < LicenseKeyFetcher::Base

      def initialize(opts = {}) end

      def validate_license_id(inputs)
        puts "Welcome you finally got here, atleast you are not a robot"
      end

      def is_license_with_valid_pattern?(inputs)
        license_id = inputs[:ask_for_license_id]
        if (match = license_id.match(/^#{LICENSE_KEY_REGEX}$/))
          inputs[:ask_for_license_id] = match[1]
          true
        else
          puts "License pattern should be #{LICENSE_KEY_PATTERN_DESC}"
          false
        end
      end

      def is_license_valid_on_server?(inputs)
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
