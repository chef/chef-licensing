require_relative "error"

module ChefLicensing
  class RestfulClientError < Error
    def message
      "License Server Error"
    end
  end
end
