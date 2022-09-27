require_relative "base"

module ChefLicensing
  module RestfulClient
    # Client that handles all License Server V1 endpoints
    class V1 < Base
      END_POINTS = {
        VALIDATE: "v1/validate",
        GENERATE_LICENSE: "v1/triallicense",
      }.freeze
    end
  end
end