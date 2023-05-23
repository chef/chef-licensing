require_relative "../restful_client/v1"
require_relative "../exceptions/list_licenses_error"
require_relative "../config"

module ChefLicensing
  module Api
    class ListLicenses
      class << self
        def info(opts = {})
          new(opts).info
        end
      end

      def initialize(opts = {})
        @restful_client = opts[:restful_client] ? opts[:restful_client].new : ChefLicensing::RestfulClient::V1.new
      end

      def info
        response = restful_client.list_licenses
        raise ChefLicensing::ListLicensesError.new(response.message, response.status_code) unless response.status_code == 200 && response.data

        response.data
      end

      private

      attr_reader :restful_client
    end
  end
end