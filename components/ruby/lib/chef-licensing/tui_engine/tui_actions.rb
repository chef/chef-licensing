require_relative "../license_key_validator"
require_relative "../license_key_generator"
require_relative "../exceptions/invalid_license"
require_relative "../exceptions/license_generation_failed"
require_relative "../exceptions/license_generation_rejected"
require_relative "../license_key_fetcher/base"
require_relative "../config"
require_relative "../list_license_keys"
require "tty-spinner"

module ChefLicensing
  class TUIEngine
    class TUIActions
      attr_accessor :logger, :output, :license_id, :error_msg, :rejection_msg, :invalid_license_msg
      def initialize(opts = {})
        @logger = ChefLicensing::Config.logger
        @output = ChefLicensing::Config.output
      end

      def is_license_with_valid_pattern?(input)
        license_id = input[:ask_for_license_id]
        input[:ask_for_license_id] = ChefLicensing::LicenseKeyFetcher::Base.verify_and_extract_license(license_id)
        true
      rescue ChefLicensing::LicenseKeyFetcher::Base::InvalidLicenseKeyFormat => e
        output.puts e.message
        logger.debug e.message
        false
      end

      def is_license_valid_on_server?(input)
        license_id = input[:ask_for_license_id]
        spinner = TTY::Spinner.new(":spinner [Running] License validation in progress...", format: :dots, clear: true)
        spinner.auto_spin # Start the spinner
        is_valid = ChefLicensing::LicenseKeyValidator.validate!(license_id)
        spinner.success # Stop the spinner
        self.license_id = license_id
        is_valid
      rescue ChefLicensing::InvalidLicense => e
        spinner.error # Stop the spinner
        self.invalid_license_msg = e.message || "Something went wrong while validating the license"
        false
      end

      def is_user_name_valid?(input)
        user_name = input[:gather_user_last_name_for_license_generation] || input[:gather_user_first_name_for_license_generation]
        (user_name =~ /\A[a-z_A-Z\-\`]{3,16}\Z/) == 0
      end

      def is_email_valid?(input)
        (input[:gather_user_email_for_license_generation] =~ URI::MailTo::EMAIL_REGEXP) == 0
      end

      def is_company_name_valid?(input)
        (input[:gather_user_company_for_license_generation] =~ /\A[a-z_.\sA-Z\-\`]{3,16}\Z/) == 0
      end

      def is_phone_no_valid?(input)
        # TODO validation logic
        true
      end

      def generate_trial_license(input)
        output.puts "License generation in progress..."
        self.license_id = ChefLicensing::LicenseKeyGenerator.generate_trial_license!(
          first_name: input[:gather_user_first_name_for_license_generation],
          last_name: input[:gather_user_last_name_for_license_generation],
          email_id: input[:gather_user_email_for_license_generation],
          product: ChefLicensing::Config.chef_product_name&.capitalize,
          company: input[:gather_user_company_for_license_generation],
          phone: input[:gather_user_phone_no_for_license_generation]
        )
        true
      rescue ChefLicensing::LicenseGenerationFailed => e
        self.error_msg = e.message
        false
      rescue ChefLicensing::LicenseGenerationRejected => e
        self.rejection_msg = e.message
        false
      end

      def generate_free_license(input)
        puts "License generation in progress..."
        self.license_id = ChefLicensing::LicenseKeyGenerator.generate_free_license!(
          first_name: input[:gather_user_first_name_for_license_generation],
          last_name: input[:gather_user_last_name_for_license_generation],
          email_id: input[:gather_user_email_for_license_generation],
          product: ChefLicensing::Config.chef_product_name&.capitalize,
          company: input[:gather_user_company_for_license_generation],
          phone: input[:gather_user_phone_no_for_license_generation]
        )
        true
      rescue ChefLicensing::LicenseGenerationFailed => e
        self.error_msg = e.message
        false
      rescue ChefLicensing::LicenseGenerationRejected => e
        self.rejection_msg = e.message
        false
      end

      def generate_commercial_license_lead(input)
        warn "\n\nCommercial license generation is not yet implemented!\n\n"
        false

        # TODO stub method definition needs to be implemented

        #   puts "License generation request in progress..."
        #   license_id = ChefLicensing.generate_commercial_license_lead!(
        #     first_name: input[:gather_user_first_name_for_license_generation],
        #     last_name: input[:gather_user_last_name_for_license_generation],
        #     email_id: input[:gather_user_email_for_license_generation],
        #     product: "inspec",
        #     company: input[:gather_user_company_for_license_generation],
        #     phone: input[:gather_user_phone_no_for_license_generation]
        #   )
        #   true
        # rescue ChefLicensing::CommercialLicenseLeadGenerationFailed => e
        #   self.error_msg = e.message
        #   false
        # rescue ChefLicensing::CommercialLicenseLeadGenerationRejected => e
        #   self.rejection_msg = e.message
        #   false
      end

      def fetch_license_id(input)
        license_id
      end

      def fetch_license_failure_error_msg(input)
        error_msg
      end

      def fetch_license_failure_rejection_msg(input)
        rejection_msg
      end

      def select_license_generation_based_on_type(inputs)
        if inputs.key? :free_license_selection
          "free"
        elsif inputs.key? :trial_license_selection
          "trial"
        else
          "commercial"
        end
      end

      def check_license_renewal(inputs)
        interaction_ids = inputs.keys
        if (interaction_ids & %i{ prompt_license_about_to_expire prompt_license_expired }).empty?
          "new"
        else
          "renew"
        end
      end

      def license_generation_rejected?(inputs)
        !!rejection_msg
      end

      def fetch_invalid_license_msg(input)
        invalid_license_msg
      end

      def display_license_info(inputs)
        ChefLicensing::ListLicenseKeys.display_overview({ license_keys: [license_id] })
      end

      def clear_license_type_selection(inputs)
        inputs.delete(:free_license_selection)
        inputs.delete(:trial_license_selection)
        inputs.delete(:commercial_license_selection)
      end

      def are_user_details_present?(inputs)
        inputs.key?(:gather_user_first_name_for_license_generation) &&
        inputs.key?(:gather_user_last_name_for_license_generation) &&
        inputs.key?(:gather_user_email_for_license_generation) &&
        inputs.key?(:gather_user_company_for_license_generation)
      end
    end
  end
end
