require_relative "license_key_fetcher"
require_relative "api/describe"
require_relative "exceptions/describe_error"
require "pastel" unless defined?(Pastel)
require_relative "config"

module ChefLicensing
  class ListLicenseKeys
    def self.display(opts = {})
      new(opts).display
    end

    def self.display_overview(opts = {})
      new(opts).display_overview
    end

    def initialize(opts = {})
      @logger = ChefLicensing::Config.logger
      @output = ChefLicensing::Config.output
      @pastel = Pastel.new
      @license_keys = fetch_license_keys(opts)
      @licenses_metadata = fetch_licenses_metadata
    end

    def display
      output.puts "+------------ License Information ------------+"
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

    def display_overview
      licenses_metadata.each do |license|
        output.puts "------------------------------------------------------------"

        # find the number of days left for the license to expire
        validity = (Date.parse(license.expiration_date) - Date.today).to_i

        output.puts <<~LICENSE
            #{pastel.bold("License Details")}
              License ID       : #{license.id}
              Type             : #{license.license_type}
              Status           : #{license.status}
              Validity         : #{validity > 0 ? validity : 0} days
        LICENSE

        # Displaying `No. of targets` makes the information specific in context of InSpec node limits.
        # The decision to display this information is a joint effort between POs and UXs.
        # TODO: Consider making this information more generic in the future.
        license.limits.each do |limit|
          output.puts <<~LIMIT
            No. of targets   : #{limit.usage_limit}
          ------------------------------------------------------------
          LIMIT
        end
      end
    end

    private

    attr_reader :pastel, :output, :logger, :license_keys, :licenses_metadata

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
      puts "No #{header.downcase} found.\n\n" if component.empty?
      component.each do |attribute|
        display_info(attribute)
      end
    end

    def puts_bold(title)
      output.puts pastel.bold(title)
    end

    def fetch_license_keys(opts = {})
      license_keys = opts[:license_keys] || ChefLicensing::LicenseKeyFetcher.fetch({ logger: logger, dir: opts[:dir] })

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
      licenses_metadata = ChefLicensing::Api::Describe.list({
        license_keys: license_keys,
      })
      logger.debug "License metadata fetched from server: #{licenses_metadata}"

      licenses_metadata
    rescue ChefLicensing::DescribeError => e
      logger.debug "Error occured while fetching license information: #{e.message}"
      output.puts "Error occured while fetching license information: #{e.message}"
      # TODO: Exit with a non-zero status code
      exit
    end
  end
end
