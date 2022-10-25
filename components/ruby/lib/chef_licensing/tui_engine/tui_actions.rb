require_relative "../license_key_validator"
require_relative "../license_key_generator"
require_relative "../exceptions/invalid_license"
require_relative "../exceptions/license_generation_failed"
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
        user_name = inputs[:gather_user_last_name_for_license_generation] || inputs[:gather_user_first_name_for_license_generation]
        return (user_name =~ /\A[a-z_A-Z\-\`]{4,16}\Z/) == 0
      end

      def is_email_valid?(inputs)
        return (inputs[:gather_user_email_for_license_generation]  =~ URI::MailTo::EMAIL_REGEXP) == 0
      end

      def is_company_name_valid?(inputs)
        return (inputs[:gather_user_company_for_license_generation] =~ /\A[a-z_.\sA-Z\-\`]{4,16}\Z/) == 0
      end

      def is_phone_no_valid?(inputs)
        # TBD validation logic
        true
      end

      # TBD to add product name dynamically
      def generate_license(inputs)
        puts "License generation in progress..."
        license_id = ChefLicensing::LicenseKeyGenerator.generate!(
          first_name: inputs[:gather_user_first_name_for_license_generation],
          last_name: inputs[:gather_user_last_name_for_license_generation],
          email_id: inputs[:gather_user_email_for_license_generation],
          product: "inspec",
          company: inputs[:gather_user_company_for_license_generation],
          phone: inputs[:gather_user_phone_no_for_license_generation]
        )
        puts "License ID: #{license_id}"
        true
      rescue ChefLicensing::LicenseGenerationFailed => e
        puts e.message
        false
      end

      def select_license_generation_based_on_type(inputs)
        if inputs.keys.include? :free_license_selection
          "free"
        elsif inputs.keys.include? :trial_license_selection
          "trial"
        else
          "commercial"
        end
      end

      def print_review_details(inputs)
        puts %{
          User Details
          ----------------------------------------------------
          Name: #{inputs[:gather_user_first_name_for_license_generation]}
          Last Name: #{inputs[:gather_user_last_name_for_license_generation]}
          Email: #{inputs[:gather_user_email_for_license_generation]}
          Company: #{inputs[:gather_user_company_for_license_generation]}
          Phone number: #{inputs[:gather_user_phone_no_for_license_generation]}
        }
      end

      def license_generation_rejected?(inputs)
        # TBD based on error handling in API
        true
      end
    end
  end
end
