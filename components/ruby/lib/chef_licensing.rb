require "chef_licensing/version"
require "chef_licensing/license_key_fetcher"
require "chef_licensing/config"
require "chef_licensing/api/describe"
require "chef_licensing/list_license_keys"
require "chef_licensing/exceptions/feature_not_entitled"
require "chef_licensing/exceptions/software_not_entitled"
require "chef_licensing/exceptions/client_error"
require "chef_licensing/api/client"

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
      ChefLicensing::LicenseKeyFetcher.fetch_and_persist
    end

    def list_license_keys_info(opts = {})
      ChefLicensing::ListLicenseKeys.display(opts)
    end

    def client(opts = {})
      @license ||= ChefLicensing::Api::Client.info(opts)
    end
  end
end
