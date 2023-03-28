require_relative "base"

module ChefLicensing
  module RestfulClient
    # Client that handles all License Server V1 endpoints
    class V1 < Base
      END_POINTS = END_POINTS.merge({
        VALIDATE: "v1/validate",
        GENERATE_LICENSE: "v1/triallicense",
        GENERATE_FREE_LICENSE: "v1/freetierlicense",
      }).freeze
    end
  end
end