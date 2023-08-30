require_relative "base"

module ChefLicensing
  module RestfulClient
    # Client that handles all License Server V1 endpoints
    class V1 < Base
      END_POINTS = END_POINTS.merge({
        VALIDATE: "v1/validate",
        CLIENT: "v1/client",
        DESCRIBE: "v1/desc",
        LIST_LICENSES: "v1/listLicenses",
      }).freeze
    end
  end
end