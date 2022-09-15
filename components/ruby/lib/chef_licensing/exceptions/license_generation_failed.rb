require_relative "error"

module ChefLicensing
  class LicenseGenerationFailed < Error
    def message
      "License Generation Failed"
    end
  end
end