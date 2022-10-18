require_relative "../license_key_validator"
require_relative "../exceptions/invalid_license"
require_relative "../license_key_fetcher/base"

module ChefLicensing
  class TUIEngine
    # TODO: Is there a better way to use the base class?
    # Base class is required for constants like LICENSE_KEY_REGEX
    class TUIActions < LicenseKeyFetcher::Base

      attr_accessor :logger, :output
      def initialize(opts = {})
        @logger = opts[:logger] || Logger.new(opts.key?(:output) ? opts[:output] : STDERR)
        @output = opts[:output] || STDOUT
      end

      def validate_license_id(inputs)
        output.puts "Welcome you finally got here, atleast you are not a robot"
      end

      def is_license_with_valid_pattern?(inputs)
        license_id = inputs[:ask_for_license_id]
        if !license_id.nil? && (match = license_id.match(/^#{LICENSE_KEY_REGEX}$/))
          inputs[:ask_for_license_id] = match[1]
          true
        else
          output.puts "License pattern should be #{LICENSE_KEY_PATTERN_DESC}"
          false
        end
      end

      def is_license_valid_on_server?(inputs)
        license_id = inputs[:ask_for_license_id]
        output.puts "License validation in progress..."
        ChefLicensing::LicenseKeyValidator.validate!(license_id)
      rescue ChefLicensing::InvalidLicense => e
        logger.debug e.message
        logger.debug("License is invalid")
        false
      end

      def is_user_name_valid?(inputs)
        # TBD validation logic
        true
      end

      def is_email_valid?(inputs)
        # TBD validation logic
        true
      end

      def is_company_name_valid?(inputs)
        # TBD validation logic
        true
      end

      def is_phone_no_valid?(inputs)
        # TBD validation logic
        true
      end

      def generate_license(inputs)
        # TBD validation logic
        true
      end

    end
  end
end
