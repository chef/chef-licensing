require_relative "../config"
require_relative "../api/list_licenses"
require_relative "../exceptions/list_licenses_error"

module ChefLicensing
  class LicensingService
    class Local
      attr_reader :logger

      class << self
        def detected?
          new.detected?
        end
      end

      def initialize
        @logger = ChefLicensing::Config.logger
      end

      def detected?
        ChefLicensing::Api::ListLicenses.info
        true
      rescue ChefLicensing::ListLicensesError => e
        # If API call returns 403, it is a global licensing service
        return false if e.status_code == 403

        logger.debug "Error occured while fetching licenses: #{e.message}"
      end
    end
  end
end