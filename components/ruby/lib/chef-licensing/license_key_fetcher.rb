require "chef-config/path_helper"
require "chef-config/windows"

require_relative "config"
require_relative "config_fetcher/arg_fetcher"
require_relative "config_fetcher/env_fetcher"
require_relative "license_key_fetcher/base"
require_relative "license_key_fetcher/file"
require_relative "license_key_fetcher/prompt"
require_relative "../chef-licensing"
require "tty-spinner"
require_relative "exceptions/invalid_license"

# LicenseKeyFetcher allows us to inspect obtain the license Key from the user in a variety of ways.
module ChefLicensing
  class LicenseKeyFetcher
    class LicenseKeyNotFetchedError < RuntimeError
    end

    class LicenseKeyNotPersistedError < RuntimeError
    end

    attr_reader :config, :license_keys, :arg_fetcher, :env_fetcher, :file_fetcher, :prompt_fetcher, :logger
    def initialize(opts = {})
      @config = opts
      @logger = ChefLicensing::Config.logger
      @config[:output] = ChefLicensing::Config.output
      config[:logger] = logger
      config[:dir] = opts[:dir]

      # This is the whole point - to obtain the license keys.
      @license_keys = []

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
      logger.debug "License Key fetcher examining CLI arg checks"
      new_keys = fetch_license_key_from_arg
      license_type = validate_and_fetch_license_type(new_keys)
      if license_type
        check_license_restriction(license_type)
        # break the flow if there is a restriction in adding license
        return new_keys unless add_license_if_not_restricted(new_keys, license_type)
      end

      logger.debug "License Key fetcher examining ENV checks"
      new_keys = fetch_license_key_from_env
      license_type = validate_and_fetch_license_type(new_keys)
      if license_type
        check_license_restriction(license_type)
        # break the flow if there is a restriction in adding license
        return new_keys unless add_license_if_not_restricted(new_keys, license_type)
      end

      # If it has previously been fetched and persisted, read from disk and set runtime decision
      logger.debug "License Key fetcher examining file checks"
      fetch_from_file

      @license_keys = @license_keys.uniq
      # licenses expiration check
      unless @license_keys.empty?
        return @license_keys if licenses_active?
      end

      # Lowest priority is to interactively prompt if we have a TTY
      if config[:output].isatty
        append_extra_info_to_tui_engine # will add extra dynamic values in tui flows
        logger.debug "License Key fetcher - detected TTY, prompting..."
        new_keys = prompt_fetcher.fetch

        unless new_keys.empty?
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
      config = {}

      # License add restrictions for multiple trial license
      if license_restricted?(:trial)
        config[:start_interaction] = :add_license_except_trial
      else
        config[:start_interaction] = :add_license_all
      end

      prompt_fetcher.config = config
      append_extra_info_to_tui_engine
      new_keys = prompt_fetcher.fetch
      unless new_keys.empty?
        prompt_fetcher.license_type ||= get_license_type(new_keys.first)
        persist_and_concat(new_keys, prompt_fetcher.license_type)
        return license_keys
      end
    end

    # Note: Fetching from arg and env as well, to be able to fetch license when disk is non-writable
    def fetch
      (fetch_license_key_from_arg << fetch_license_key_from_env << @file_fetcher.fetch).flatten.uniq
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
      extra_info[:license_type] = license.license_type unless @license_keys.empty? && !license

      unless info.empty? # ability to add info hash through arguments
        info.each do |key, value|
          extra_info[key] = value
        end
      end
      prompt_fetcher.append_info_to_tui_engine(extra_info) unless extra_info.empty?
    end

    def fetch_from_file
      if file_fetcher.persisted?
        # This could be useful if the file was writable in past but is not writable in current scenario and new keys are not persisted in the file
        file_keys = file_fetcher.fetch
        @license_keys.concat(file_keys).uniq # uniq is required in case file was a writable and to avoid repeated values.
      end
      @license_keys
    end

    def licenses_active?
      spinner = TTY::Spinner.new(":spinner [Running] License validation in progress...", format: :dots, clear: true)
      spinner.auto_spin # Start the spinner
      # This call returns a license based on client logic
      # This API call is only made when multiple license keys are present or if client call was never done
      self.license = ChefLicensing.client(license_keys: @license_keys) if !license || @license_keys.count > 1
      spinner.success # Stop the spinner
      if license.expired? || license.have_grace?
        config[:start_interaction] = :prompt_license_expired
        prompt_fetcher.config = config
        false
      elsif license.about_to_expire?
        config[:start_interaction] = :prompt_license_about_to_expire
        prompt_fetcher.config = config
        false
      else
        true
      end
    end

    def validate_and_fetch_license_type(new_keys)
      unless new_keys.empty?
        is_valid = validate_license_key(new_keys.first)
        return get_license_type(new_keys.first) if is_valid
      end
    end

    def license_type_generation_options
      # TODO free license restrictions
      license_types = %i{free trial commercial}
      existing_license_types = file_fetcher.fetch_license_types

      license_types -= [:trial] if existing_license_types.include? :trial
      license_types.uniq
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
      license_type_options = license_type_generation_options
      !(license_type_options.include? license_type)
    end

    def prompt_license_addition_restricted(license_type)
      # For trial license
      # TODO for free license
      config[:start_interaction] = :prompt_license_addition_restriction
      prompt_fetcher.config = config
      # Existing license keys needs to be fetcher to show details of existing license of license type which is restricted.
      existing_license_keys = file_fetcher.filter_license_keys_based_on_type(license_type)
      append_extra_info_to_tui_engine({ license_id: existing_license_keys.first, license_type: license_type })
      prompt_fetcher.fetch
    end

    # used for env and argument fetched licenses before persisting
    def add_license_if_not_restricted(new_keys, license_type)
      license_restricted?(license_type) ? false : persist_and_concat(new_keys, license_type)
    end

    def check_license_restriction(license_type)
      # prompted after argument and env fetcher to check for license restriction
      prompt_license_addition_restricted(license_type) if license_restricted?(license_type)
    end
  end
end