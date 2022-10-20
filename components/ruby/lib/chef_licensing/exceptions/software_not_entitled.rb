require_relative "error"

module ChefLicensing
  class SoftwareNotEntitled < Error
    def message
      super || "Software not entitled"
    end
  end
end