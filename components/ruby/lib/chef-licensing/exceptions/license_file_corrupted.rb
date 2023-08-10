require_relative "error"

module ChefLicensing
  class LicenseFileCorrupted < Error
    def message
      super || "License file contents are corrupted"
    end
  end
end
