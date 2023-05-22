require_relative "error"

module ChefLicensing
  class ListLicensesError < Error
    def message
      super || "List Licenses API failure"
    end
  end
end