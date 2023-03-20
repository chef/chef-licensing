require_relative "error"

module ChefLicensing
  class DescribeError < Error
    def message
      super || "License Describe API failure"
    end
  end
end