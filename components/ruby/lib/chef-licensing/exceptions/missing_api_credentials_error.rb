module ChefLicensing
  class MissingAPICredentialsError < Error
    def message
      super || "Missing API credentials. Check README for more details."
    end
  end
end