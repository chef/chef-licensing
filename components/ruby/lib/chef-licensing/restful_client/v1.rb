require_relative "base"

module ChefLicensing
  module RestfulClient
    # Client that handles all License Server V1 endpoints
    class V1 < Base
      END_POINTS = END_POINTS.merge({
        VALIDATE: "v1/validate",
        GENERATE_TRIAL_LICENSE: "v1/trial",
        GENERATE_FREE_LICENSE: "v1/free",
        CLIENT: "v1/client",
        DESCRIBE: "v1/desc",
        LIST_LICENSES: "v1/listLicenses",
      }).freeze

      CACHE_ENDPOINTS = [
        END_POINTS[:CLIENT],
      ].freeze
    end
  end
end
