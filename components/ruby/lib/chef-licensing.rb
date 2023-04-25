require "chef-licensing/version"
require "chef-licensing/license_key_fetcher"
require "chef-licensing/config"
require "chef-licensing/api/describe"
require "chef-licensing/list_license_keys"
require "chef-licensing/exceptions/feature_not_entitled"
require "chef-licensing/exceptions/software_not_entitled"
require "chef-licensing/exceptions/client_error"
require "chef-licensing/api/client"
require "chef-licensing/license_key_fetcher/prompt"

module ChefLicensing
  class << self

    # @example
    #   ChefLicensing.configure do |config|
    #     config.licensing_server_url  = 'LICENSE_SERVER'
    #     config.logger = Logger.new($stdout)
    #   end
    def configure(&block)
      yield(ChefLicensing::Config)
    end

    def check_feature_entitlement!(feature_name: nil, feature_id: nil)
      # Checking for feature presence in license feature entitlements
      license = client(license_keys: license_keys)
      feature_entitlements = license.feature_entitlements.select { |feature| feature.id == feature_id || feature.name == feature_name }
      if feature_entitlements.empty?
        raise(ChefLicensing::FeatureNotEntitled)
      else
        true
      end
    end

    def check_software_entitlement!
      # If API call is not breaking that means license is entitled.
      client(license_keys: license_keys)
      true
    rescue ChefLicensing::ClientError => e
      # Checking specific text phrase for entitlement error
      if e.message.match?(/not entitled/)
        raise(ChefLicensing::SoftwareNotEntitled)
      else
        raise
      end
    end

    # @note no in-memory caching of the licenses so that it fetches updated licenses always
    def license_keys
      ChefLicensing::LicenseKeyFetcher.fetch
    end

    # @note fetch_and_persist is invoked by chef-products to fetch and persist the license keys
    def fetch_and_persist
      ChefLicensing::LicenseKeyFetcher.fetch_and_persist
    end

    def list_license_keys_info(opts = {})
      ChefLicensing::ListLicenseKeys.display(opts)
    end

    def client(opts = {})
      ChefLicensing::Api::Client.info(opts)
    end

    def add_license
      ChefLicensing::LicenseKeyFetcher.add_license
    end
  end
end
