require_relative "license_key_fetcher"
require_relative "api/license_describe"

module ChefLicensing
  class ListLicenseKeys

    def self.display(opts = {})
      new(opts).display
    end

    def initialize(opts = {})
      @cl_config = opts[:cl_config] || ChefLicensing::Config.instance
      @license_keys = opts[:license_keys] || ChefLicensing::LicenseKeyFetcher.fetch_and_persist({ logger: cl_config.logger })
    end

    def display
      licenses_metadata = ChefLicensing::Api::LicenseDescribe.list({
        license_keys: license_keys,
        entitlement_id: "something",
        cl_config: cl_config,
      })

      if licenses_metadata.empty?
        puts "No information found for the license keys provided."
        return
      end

      puts "----------- License Keys Information -----------"
      puts "Total License Keys found: #{licenses_metadata.length}"
      puts "\nDetails:"

      licenses_metadata.each do |license|
        puts <<~LICENSE
          Key             : #{license.id}
          Type            : #{license.license_type}
          Status          : #{license.status}
          Expiration Date : #{license.expiration_date}
        LICENSE

        puts "Software Entitlements:"
        license.software_entitlements.each do |software|
          display_info(software)
        end

        puts "Asset Entitlements:"
        license.asset_entitlements.each do |asset|
          display_info(asset)
        end

        puts "Feature Entitlements:"
        license.feature_entitlements.each do |feature|
          display_info(feature)
        end

        puts "Limits:"
        license.limits.each do |limit|
          puts <<~LIMIT
            Usage Status  : #{limit.usage_status}
            Usage Limit   : #{limit.usage_limit}
            Usage Measure : #{limit.usage_measure}
            Used          : #{limit.used}
            Software      : #{limit.software}
          LIMIT
        end
      end

      puts "----------------------------------------------"
    end

    private

    attr_reader :license_keys, :cl_config

    def display_info(component)
      puts <<~INFO
        ID       : #{component.id}
        Name     : #{component.name}
        Status   : #{component.status}
        Entitled : #{component.entitled}
      INFO
      puts "\n"
    end
  end
end

# a = ChefLicensing::ListLicenseKeys.display
