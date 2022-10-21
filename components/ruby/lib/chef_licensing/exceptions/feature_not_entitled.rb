require_relative "error"

module ChefLicensing
  class FeatureNotEntitled < Error
    def message
      super || "Feature not entitled"
    end
  end
end
