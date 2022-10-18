require "chef_licensing/version"
require "chef_licensing/license_feature_entitlement"
require "chef_licensing/license_key_fetcher"
require "chef_licensing/config"
require "chef_licensing/license_software_entitlement"

module ChefLicensing
  class << self
    def check_feature_entitlement!(feature)
      ChefLicensing::LicenseFeatureEntitlement.check_entitlement!(license_keys, feature_name: feature)
    end

    def check_software_entitlement!(software_entitlement_name: nil, software_entitlement_id: nil)
      ChefLicensing::LicenseSoftwareEntitlement.check!(license_keys: license_keys, software_entitlement_name: software_entitlement_name, software_entitlement_id: software_entitlement_id)
    end

    # @note no in-memory caching of the licenses so that it fetches updated licenses always
    def license_keys
      ChefLicensing::LicenseKeyFetcher.fetch_and_persist
    end
  end
end
