require "chef-config/path_helper"
require "chef-config/windows"

require_relative "config"
require_relative "context"
require_relative "config_fetcher/arg_fetcher"
require_relative "config_fetcher/env_fetcher"
require_relative "license_key_fetcher/base"
require_relative "license_key_fetcher/file"
require_relative "license_key_fetcher/prompt"
require_relative "../chef-licensing"
require "tty-spinner"
require_relative "exceptions/invalid_license"
require_relative "exceptions/error"
require_relative "exceptions/client_error"

# LicenseKeyFetcher allows us to inspect obtain the license Key from the user in a variety of ways.
module ChefLicensing
  class LicenseKeyFetcher
    class LicenseKeyNotFetchedError < RuntimeError
    end

    class LicenseKeyNotPersistedError < RuntimeError
    end

    class LicenseKeyAddNotAllowed < Error
    end

    attr_reader :config, :license_keys, :arg_fetcher, :env_fetcher, :file_fetcher, :prompt_fetcher, :logger
    attr_accessor :client_api_call_error

    def initialize(opts = {})
      @config = opts
      @logger = ChefLicensing::Config.logger
      @config[:output] = ChefLicensing::Config.output
      config[:logger] = logger
      config[:dir] = opts[:dir]

      # While using on-prem licensing service, @license_keys are fetched from API
      logger.debug "License Key fetcher - fetching license keys depending upon the context (either API or file)"
      # While using global licensing service, @license_keys are fetched from file
      @license_keys = ChefLicensing::Context.license_keys(opts) || []

      argv = opts[:argv] || ARGV
      env = opts[:env] || ENV

      # The various things that have a say in fetching the license Key.
      @arg_fetcher = ChefLicensing::ArgFetcher.new(argv)
      @env_fetcher = ChefLicensing::EnvFetcher.new(env)
      @file_fetcher = LicenseKeyFetcher::File.new(config)
      @prompt_fetcher = LicenseKeyFetcher::Prompt.new(config)
      @license = nil
    end

    #
    # Methods for obtaining consent from the user.
    #
    def fetch_and_persist
      if ChefLicensing::Context.local_licensing_service?
        perform_on_prem_operations
      else
        perform_global_operations
      end
    end

    def perform_on_prem_operations
      # While using on-prem licensing service no option to add/generate license is enabled

      new_keys = fetch_license_key_from_arg
      raise LicenseKeyAddNotAllowed.new("'--chef-license-key <value>' option is not supported with airgapped environment. You cannot add license from airgapped environment.") unless new_keys.empty?

      unless @license_keys.empty?
        # Licenses expiration check
        # Client API possible errors will be handled in software entitlement check call (made after this)
        # client_api_call_error is set to true when there is an error in licenses_active? call
        if licenses_active? || client_api_call_error
          return @license_keys
        else
          # Prompts if the keys are expired or expiring
          if config[:output].isatty
            append_extra_info_to_tui_engine # will add extra dynamic values in tui flows
            logger.debug "License Key fetcher - detected TTY, prompting..."
            prompt_fetcher.fetch
          end
        end
      end

      # Scenario: When a user is prompted for license expiry and license is not yet renewed
      if %i{prompt_license_about_to_expire prompt_license_expired_local_mode}.include?(config[:start_interaction])
        # Not blocking any license type in case of expiry
        return @license_keys
      end

      # Otherwise nothing was able to fetch a license. Throw an exception.
      logger.debug "License Key fetcher - no license Key able to be fetched."
      raise LicenseKeyNotFetchedError.new("Unable to obtain a License Key.")
    end

    def perform_global_operations
      logger.debug "License Key fetcher examining CLI arg checks"
      new_keys = fetch_license_key_from_arg
      license_type = validate_and_fetch_license_type(new_keys)
      if license_type && !unrestricted_license_added?(new_keys, license_type)
        # break the flow after the prompt if there is a restriction in adding license
        # and return the license keys persisted in the file or @license_keys if any
        return license_keys
      end

      logger.debug "License Key fetcher examining ENV checks"
      new_keys = fetch_license_key_from_env
      license_type = validate_and_fetch_license_type(new_keys)
      if license_type && !unrestricted_license_added?(new_keys, license_type)
        # break the flow after the prompt if there is a restriction in adding license
        # and return the license keys persisted in the file or @license_keys if any
        return license_keys
      end

      # Return keys if license keys are active and not expired or expiring
      # Return keys if there is any error in /client API call, and do not block the flow.
      # Client API possible errors will be handled in software entitlement check call (made after this)
      # client_api_call_error is set to true when there is an error in licenses_active? call
      return @license_keys if (!@license_keys.empty? && licenses_active?) || client_api_call_error

      # Lowest priority is to interactively prompt if we have a TTY
      if config[:output].isatty
        append_extra_info_to_tui_engine # will add extra dynamic values in tui flows
        logger.debug "License Key fetcher - detected TTY, prompting..."
        new_keys = prompt_fetcher.fetch

        unless new_keys.empty?
          # If license type is not selected using TUI, assign it using API call to fetch type.
          prompt_fetcher.license_type ||= get_license_type(new_keys.first)
          persist_and_concat(new_keys, prompt_fetcher.license_type)
          return license_keys
        end
      end

      # Scenario: When a user is prompted for license expiry and license is not yet renewed
      if new_keys.empty? && %i{prompt_license_about_to_expire prompt_license_expired}.include?(config[:start_interaction])
        # Not blocking any license type in case of expiry
        return @license_keys
      end

      # Otherwise nothing was able to fetch a license. Throw an exception.
      logger.debug "License Key fetcher - no license Key able to be fetched."
      raise LicenseKeyNotFetchedError.new("Unable to obtain a License Key.")
    end

    def add_license
      logger.debug "License Key fetcher - add license flow, starting..."
      if ChefLicensing::Context.local_licensing_service?
        raise LicenseKeyAddNotAllowed.new("'inspec license add' command is not supported with airgapped environment. You cannot generate license from airgapped environment.")
      else
        config = {}
        config[:start_interaction] = :add_license_all
        prompt_fetcher.config = config
        append_extra_info_to_tui_engine
        new_keys = prompt_fetcher.fetch
        unless new_keys.empty?
          prompt_fetcher.license_type ||= get_license_type(new_keys.first)
          persist_and_concat(new_keys, prompt_fetcher.license_type)
          license_keys
        end
      end
    end

    # Note: Fetching from arg and env as well, to be able to fetch license when disk is non-writable
    def fetch
      # While using on-prem licensing service, @license_keys have been fetched from API
      # While using global licensing service, @license_keys have been fetched from file
      (fetch_license_key_from_arg << fetch_license_key_from_env << @license_keys).flatten.uniq
    end

    def self.fetch_and_persist(opts = {})
      new(opts).fetch_and_persist
    end

    def self.fetch(opts = {})
      new(opts).fetch
    end

    def self.add_license(opts = {})
      new(opts).add_license
    end

    private

    attr_accessor :license

    def append_extra_info_to_tui_engine(info = {})
      extra_info = {}

      # default values
      extra_info[:chef_product_name] = ChefLicensing::Config.chef_product_name&.capitalize
      # Note: The unit measure is decided by the UX/Product.
      extra_info[:unit_measure] = ChefLicensing::Config.chef_product_name&.downcase == "inspec" ? "targets" : "nodes"
      if license
        extra_info[:license_type] = license.license_type.capitalize
        extra_info[:number_of_days_in_expiration] = license.number_of_days_in_expiration
        extra_info[:license_expiration_date] = Date.parse(license.expiration_date).strftime("%a, %d %b %Y")
      end

      unless info.empty? # ability to add info hash through arguments
        info.each do |key, value|
          extra_info[key] = value
        end
      end
      prompt_fetcher.append_info_to_tui_engine(extra_info) unless extra_info.empty?
    end

    def licenses_active?
      logger.debug "License Key fetcher - checking if licenses are active"
      spinner = TTY::Spinner.new(":spinner [Running] License validation in progress...", format: :dots, clear: true, output: config[:output])
      spinner.auto_spin # Start the spinner
      # This call returns a license based on client logic
      # This API call is only made when multiple license keys are present or if client call was never done
      self.license = ChefLicensing.client(license_keys: @license_keys) if !license || @license_keys.count > 1
      # Intentional lag of 2 seconds when license is expiring or expired
      sleep 2 if license.expiring_or_expired?
      spinner.success # Stop the spinner
      if license.expired? || license.have_grace?
        if ChefLicensing::Context.local_licensing_service?
          config[:start_interaction] = :prompt_license_expired_local_mode
        else
          config[:start_interaction] = :prompt_license_expired
        end
        prompt_fetcher.config = config
        false
      elsif license.about_to_expire?
        config[:start_interaction] = :prompt_license_about_to_expire
        prompt_fetcher.config = config
        false
      else
        true
      end
    rescue ChefLicensing::ClientError => e
      spinner.success
      logger.debug "Error in License Expiration Check using Client API #{e.message}"
      self.client_api_call_error = true
      false
    end

    def validate_and_fetch_license_type(new_keys)
      unless new_keys.empty?
        is_valid = validate_license_key(new_keys.first)
        return get_license_type(new_keys.first) if is_valid
      end
    end

    def persist_and_concat(new_keys, license_type)
      file_fetcher.persist(new_keys.first, license_type)
      @license_keys.concat(new_keys)
    end

    def fetch_license_key_from_arg
      new_key = @arg_fetcher.fetch_value("--chef-license-key")
      validate_license_key_format(new_key)
    end

    def fetch_license_key_from_env
      new_key = @env_fetcher.fetch_value("CHEF_LICENSE_KEY")
      validate_license_key_format(new_key)
    end

    def validate_license_key_format(license_key)
      return [] if license_key.nil?

      license_key = ChefLicensing::LicenseKeyFetcher::Base.verify_and_extract_license(license_key)
      [license_key]
    end

    def validate_license_key(license_key)
      ChefLicensing::LicenseKeyValidator.validate!(license_key)
    end

    def get_license_type(license_key)
      self.license = ChefLicensing.client(license_keys: [license_key])
      license.license_type.downcase.to_sym
    end

    def license_restricted?(license_type)
      allowed_license_types = file_fetcher.fetch_allowed_license_types_for_addition
      !(allowed_license_types.include? license_type)
    end

    def prompt_license_addition_restricted(license_type, existing_license_keys_in_file)
      logger.debug "License Key fetcher - prompting license addition restriction"
      # For trial license
      # TODO for Free Tier License
      config[:start_interaction] = :prompt_license_addition_restriction
      prompt_fetcher.config = config
      # Existing license keys are needed to show details of existing license of license type which is restricted.
      append_extra_info_to_tui_engine({ license_id: existing_license_keys_in_file.last, license_type: license_type })
      prompt_fetcher.fetch
    end

    def unrestricted_license_added?(new_keys, license_type)
      if license_restricted?(license_type)
        # Existing license keys of same license type are fetched to compare if old license key or a new one is added.
        # However, if user is trying to add Free Tier License, and user has active trial license, we fetch the trial license key
        if license_type == :free && file_fetcher.user_has_active_trial_license?
          existing_license_keys_in_file = file_fetcher.fetch_license_keys_based_on_type(:trial)
        else
          existing_license_keys_in_file = file_fetcher.fetch_license_keys_based_on_type(license_type)
        end
        # Only prompt when a new trial license is added
        unless existing_license_keys_in_file.last == new_keys.first
          # prompt the message that this addition of license is restricted.
          prompt_license_addition_restricted(license_type, existing_license_keys_in_file)
          return false
        end
        true # license type is restricted but not the key since it is the same key hence returning true
      else
        persist_and_concat(new_keys, license_type)
        true
      end
    end
  end
end
