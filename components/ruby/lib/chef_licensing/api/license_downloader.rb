require_relative "../restful_client/v1"
require_relative "../exceptions/license_download_failed"

module ChefLicensing
  module Api
    class LicenseDownloader
      attr_reader :license_key

      class << self
        def download(opts = {})
          new(opts).download
        end
      end

      def initialize(opts = {})
        @license_key = opts[:license_key] || raise(ArgumentError, "Missing Params: `license_key`")
        @restful_client = opts[:restful_client] ? opts[:restful_client].new : ChefLicensing::RestfulClient::V1.new
      end

      def download
        restful_client.download(license_key)
        # TODO handle download failure scenario after the api corrections
        # response = restful_client.download(license_key)
        # response.data || raise(ChefLicensing::LicenseDownloadFailed, response.message)
      end

      private

      attr_reader :restful_client
    end
  end
end