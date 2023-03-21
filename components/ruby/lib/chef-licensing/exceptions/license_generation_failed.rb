require_relative "error"

module ChefLicensing
  class LicenseGenerationFailed < Error
    def message
      super || "License Generation Failed"
    end
  end
end