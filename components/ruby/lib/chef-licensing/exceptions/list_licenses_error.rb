require_relative "error"

module ChefLicensing
  class ListLicensesError < Error
    attr_reader :status_code

    def initialize(message, status_code)
      @status_code = status_code
      super(message)
    end
  end
end