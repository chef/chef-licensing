require "chef_licensing/version"
require "chef_licensing/license_key_fetcher"
require "chef_licensing/config"
require "chef_licensing/api/describe"
require "chef_licensing/list_license_keys"
require "chef_licensing/exceptions/feature_not_entitled"
require "chef_licensing/exceptions/software_not_entitled"
require "chef_licensing/api/client"

module ChefLicensing
  class << self
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
      # Checking for software entitlements presence
      license = client(license_keys: license_keys)
      if license.software_entitlements.empty?
        raise(ChefLicensing::SoftwareNotEntitled)
      else
        true
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
