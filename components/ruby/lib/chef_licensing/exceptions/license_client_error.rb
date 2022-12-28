require_relative "error"

module ChefLicensing
  class LicenseClientError < Error
    def message
      super || "License Client API failure"
    end
  end
end