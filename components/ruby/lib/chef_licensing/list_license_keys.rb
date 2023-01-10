require_relative "license_key_fetcher"
require_relative "api/license_describe"
require "pastel" unless defined?(Pastel)
module ChefLicensing
  class ListLicenseKeys
    def self.display(opts = {})
      new(opts).display
    end

    def initialize(opts = {})
      @cl_config = opts[:cl_config] || ChefLicensing::Config.instance
      @license_keys = opts[:license_keys] || ChefLicensing::LicenseKeyFetcher.fetch_and_persist({
                                                                                                  logger: cl_config.logger,
                                                                                                })
      @pastel = Pastel.new
    end

    def display
      # TODO: Entitlement ID is not required for describe API;
      # it could be obtained from the cl_config
      licenses_metadata = ChefLicensing::Api::LicenseDescribe.list({
                                                                     license_keys: license_keys,
                                                                     entitlement_id: "something",
                                                                     cl_config: cl_config,
                                                                   })

      if licenses_metadata.empty?
        puts_bold "No license keys information found on your system."
        return
      end

      puts "+---------- License Keys Information ----------+"
      puts "Total License Keys found: #{licenses_metadata.length}\n\n"

      licenses_metadata.each do |license|
        puts_bold "License Key     : #{license.id}"
        puts <<~LICENSE
          Type            : #{license.license_type}
          Status          : #{license.status}
          Expiration Date : #{license.expiration_date}

        LICENSE

        iterate_attributes(license.software_entitlements, "Software Entitlements")
        iterate_attributes(license.asset_entitlements, "Asset Entitlements")
        iterate_attributes(license.feature_entitlements, "Feature Entitlements")

        puts_bold "License Limits"
        license.limits.each do |limit|
          puts <<~LIMIT
            Usage Status  : #{limit.usage_status}
            Usage Limit   : #{limit.usage_limit}
            Usage Measure : #{limit.usage_measure}
            Used          : #{limit.used}
            Software      : #{limit.software}
          LIMIT
        end
        puts "+----------------------------------------------+"
      end
    end

    private

    attr_reader :license_keys, :cl_config, :pastel

    def display_info(component)
      puts <<~INFO
        ID       : #{component.id}
        Name     : #{component.name}
        Status   : #{component.status}
        Entitled : #{component.entitled}
      INFO
      puts "\n"
    end

    def iterate_attributes(component, header)
      puts_bold header
      component.each do |attribute|
        display_info(attribute)
      end
    end

    def puts_bold(title)
      puts pastel.bold(title)
    end
  end
end
