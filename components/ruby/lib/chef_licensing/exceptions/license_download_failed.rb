require_relative "error"

module ChefLicensing
  class LicenseDownloadFailed < Error
    def message
      super || "License Download Failed"
    end
  end
end