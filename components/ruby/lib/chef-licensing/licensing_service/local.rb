require_relative "../config"
require_relative "../api/local/licenses_list"

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
        # DUMMY call added - dependent on API integration
        ChefLicensing::Api::Local::LicensesList.info
        true
      rescue ChefLicensing::LicensesListError => e
        # If API call returns 403, it is a global licensing service
        return false if e.status_code == 403

        logger.debug "Error occured while fetching licenses: #{e.message}"
      end
    end
  end
end
