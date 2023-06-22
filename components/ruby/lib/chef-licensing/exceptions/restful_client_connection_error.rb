require_relative "error"

module ChefLicensing
  class RestfulClientConnectionError < Error
    def message
      super || "License Server Connection Error"
    end
  end
end
