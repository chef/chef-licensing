require_relative "error"

module ChefLicensing
  class RestfulClientError < Error
    def message
      super || "License Server Error"
    end
  end
end
