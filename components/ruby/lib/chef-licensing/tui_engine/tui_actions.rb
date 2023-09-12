require_relative "../license_key_validator"
require_relative "../exceptions/invalid_license"
require_relative "../license_key_fetcher/base"
require_relative "../config"
require_relative "../context"
require_relative "../list_license_keys"
require "tty-spinner"

module ChefLicensing
  class TUIEngine
    class TUIActions
      attr_accessor :logger, :output, :license_id, :error_msg, :rejection_msg, :invalid_license_msg, :license_type, :license
      def initialize(opts = {})
        @opts = opts
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
        spinner = TTY::Spinner.new(":spinner [Running] License validation in progress...", format: :dots, clear: true, output: output)
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

      def is_license_allowed?(input)
        client_api_call(license_id)
        self.license_type = get_license_type
        if license_restricted?(license_type)
          # Existing license keys needs to be fetcher to show details of existing license of license type which is restricted.
          # However, if user is trying to add Free Tier License, and user has active trial license, we fetch the trial license key
          if license_type == :free && LicenseKeyFetcher::File.user_has_active_trial_license?(@opts)
            existing_license_keys_in_file = LicenseKeyFetcher::File.fetch_license_keys_based_on_type(:trial, @opts)
          else
            existing_license_keys_in_file = LicenseKeyFetcher::File.fetch_license_keys_based_on_type(license_type, @opts)
          end
          self.license_id = existing_license_keys_in_file.last
          false
        else
          true
        end
      end

      def license_expiration_status?(input)
        get_license(license_id)
        if license.expired? || license.have_grace?
          ChefLicensing::Context.local_licensing_service? ? "expired_in_local_mode" : "expired"
        elsif license.about_to_expire?
          input[:license_expiration_date] = Date.parse(license.expiration_date).strftime("%a, %d %b %Y")
          input[:number_of_days_in_expiration] = license.number_of_days_in_expiration
          "about_to_expire"
        else
          "active"
        end
      end

      def fetch_license_id(input)
        license_id
      end

      def fetch_invalid_license_msg(input)
        invalid_license_msg
      end

      def display_license_info(inputs)
        ChefLicensing::ListLicenseKeys.display_overview({ license_keys: [license_id] })
      end

      def set_license_info(input)
        self.license_id = input[:license_id]
        self.license_type = input[:license_type]
      end

      def determine_restriction_type(input)
        if license_type == :free && LicenseKeyFetcher::File.user_has_active_trial_license?(@opts)
          "active_trial_restriction"
        else
          "#{license_type}_restriction"
        end
      end

      def fetch_license_type_restricted(inputs)
        if license_restricted?(:trial) && license_restricted?(:free)
          "trial_and_free"
        elsif license_restricted?(:trial)
          "trial"
        else
          "free"
        end
      end

      def filter_license_type_options(inputs)
        if (license_restricted?(:trial) && license_restricted?(:free)) || LicenseKeyFetcher::File.user_has_active_trial_license?(@opts)
          "ask_for_commercial_only"
        elsif license_restricted?(:trial)
          "ask_for_license_except_trial"
        elsif license_restricted?(:free)
          "ask_for_license_except_free"
        else
          "ask_for_all_license_type"
        end
      end

      private

      attr_accessor :opts

      def get_license(license_key)
        spinner = TTY::Spinner.new(":spinner [Running] License validation in progress...", format: :dots, clear: true, output: output)
        spinner.auto_spin # Start the spinner
        client_api_call(license_key)
        spinner.success # Stop the spinner
      end

      def client_api_call(license_key)
        self.license ||= ChefLicensing.client(license_keys: [license_key])
      end

      def get_license_type
        license.license_type.downcase.to_sym
      end

      def license_restricted?(license_type)
        file_fetcher = LicenseKeyFetcher::File.new(@opts)
        allowed_license_types = file_fetcher.fetch_allowed_license_types_for_addition
        !(allowed_license_types.include? license_type)
      end
    end
  end
end
