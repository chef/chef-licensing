require_relative "error"

module ChefLicensing
  class LicenseDescribeError < Error
    def message
      super || "License Describe API failure"
    end
  end
end