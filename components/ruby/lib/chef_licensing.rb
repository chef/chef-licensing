require "chef_licensing/version"
require "chef_licensing/api/license_feature_entitlement"
require "chef_licensing/license_key_fetcher"
require "chef_licensing/config"
require "chef_licensing/api/license_software_entitlement"
require "chef_licensing/api/license_downloader"

module ChefLicensing
  class << self
    def check_feature_entitlement!(feature_name: nil, feature_id: nil)
      ChefLicensing::Api::LicenseFeatureEntitlement.check_entitlement!(license_keys: license_keys, feature_name: feature_name, feature_id: feature_id)
    end

    def check_software_entitlement!(software_entitlement_name: nil, software_entitlement_id: nil)
      ChefLicensing::Api::LicenseSoftwareEntitlement.check!(license_keys: license_keys, software_entitlement_name: software_entitlement_name, software_entitlement_id: software_entitlement_id)
    end

    def download_license(opts = {})
      @license ||= ChefLicensing::Api::LicenseDownloader.download(opts)
    end

    def list_licenses
      # to list all the licenses by fetching keys from file and calling download on them.
    end

    # @note no in-memory caching of the licenses so that it fetches updated licenses always
    def license_keys
      ChefLicensing::LicenseKeyFetcher.fetch_and_persist
    end
  end
end
