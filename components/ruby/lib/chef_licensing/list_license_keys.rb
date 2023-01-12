require_relative "license_key_fetcher"
require_relative "api/license_describe"
require_relative "exceptions/license_describe_error"
require "pastel" unless defined?(Pastel)
module ChefLicensing
  class ListLicenseKeys
    def self.display(opts = {})
      new(opts).display
    end

    def initialize(opts = {})
      @cl_config = opts[:cl_config] || ChefLicensing::Config.instance
      @logger = cl_config.logger
      @output = opts[:output] || STDOUT
      @pastel = Pastel.new
      @license_keys = fetch_license_keys(opts)
    end

    def display
      licenses_metadata = fetch_licenses_metadata

      output.puts "+------------ Licenses Information ------------+"
      output.puts "Total Licenses found: #{licenses_metadata.length}\n\n"

      licenses_metadata.each do |license|
        puts_bold "License Key     : #{license.id}"
        output.puts <<~LICENSE
          Type            : #{license.license_type}
          Status          : #{license.status}
          Expiration Date : #{license.expiration_date}

        LICENSE

        iterate_attributes(license.software_entitlements, "Software Entitlements")
        iterate_attributes(license.asset_entitlements, "Asset Entitlements")
        iterate_attributes(license.feature_entitlements, "Feature Entitlements")

        puts_bold "License Limits"
        license.limits.each do |limit|
          output.puts <<~LIMIT
            Usage Status  : #{limit.usage_status}
            Usage Limit   : #{limit.usage_limit}
            Usage Measure : #{limit.usage_measure}
            Used          : #{limit.used}
            Software      : #{limit.software}
          LIMIT
        end
        output.puts "+----------------------------------------------+"
      end
    end

    private

    attr_reader :cl_config, :pastel, :output, :logger, :license_keys

    def display_info(component)
      output.puts <<~INFO
        ID       : #{component.id}
        Name     : #{component.name}
        Status   : #{component.status}
        Entitled : #{component.entitled}
      INFO
      output.puts "\n"
    end

    def iterate_attributes(component, header)
      puts_bold header
      component.each do |attribute|
        display_info(attribute)
      end
    end

    def puts_bold(title)
      output.puts pastel.bold(title)
    end

    def fetch_license_keys(opts = {})
      # Note: - Currently fetch only returns license keys from file stored on disk.
      # - We are not yet covering the case where the disk is not writable.
      # - Ability to fetch license_keys from opts makes testing easy and fast.
      # TODO: Do we need to fetch license keys from env and arg as well?
      license_keys = opts[:license_keys] || ChefLicensing::LicenseKeyFetcher.fetch({ logger: cl_config.logger, dir: opts[:dir] })

      if license_keys.empty?
        logger.debug "No license keys found on disk."
        output.puts "No license keys found on disk."
        exit
      end
      logger.debug "License keys fetched from disk: #{license_keys}"

      license_keys
    rescue ChefLicensing::LicenseKeyFetcher::LicenseKeyNotFetchedError => e
      logger.debug "Error occured while fetching license keys from disk: #{e.message}"
      output.puts "Error occured while fetching license keys from disk: #{e.message}"
      # TODO: Exit with a non-zero status code
      exit
    end

    def fetch_licenses_metadata
      licenses_metadata = ChefLicensing::Api::LicenseDescribe.list({
        license_keys: license_keys,
        entitlement_id: cl_config.chef_entitlement_id,
        cl_config: cl_config,
      })
      logger.debug "License metadata fetched from server: #{licenses_metadata}"

      licenses_metadata
    rescue ChefLicensing::LicenseDescribeError => e
      logger.debug "Error occured while fetching licenses information: #{e.message}"
      output.puts "Error occured while fetching licenses information: #{e.message}"
      # TODO: Exit with a non-zero status code
      exit
    end
  end
end
