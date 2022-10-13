require "chef_licensing/version"
require "chef_licensing/license_feature_entitlement"
require "chef_licensing/license_key_fetcher"

module ChefLicensing
  class << self
    def check_feature_entitlement!(feature)
      ChefLicensing::LicenseFeatureEntitlement.check_entitlement!(license_keys, feature_name: feature)
    end

    # @note no in-memory caching of the licenses so that it fetches updated licenses always
    def license_keys
      # TODO: remove redundant args
      ChefLicensing::LicenseKeyFetcher.fetch_and_persist(logger: Logger.new($stdout))
    end
  end
end