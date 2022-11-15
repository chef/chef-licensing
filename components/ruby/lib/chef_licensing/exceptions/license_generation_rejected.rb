module ChefLicensing
  class LicenseGenerationRejected < Error
    def message
      super || "License Generation Rejected"
    end
  end
end