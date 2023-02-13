require "net/http" unless defined?(Net::HTTP)
require_relative "../config"

module ChefLicensing
  class AirGapDetection
    class Ping

      # If status is true, airgap mode is on - we are isolated.
      attr_reader :url, :status, :logger

      def initialize(base_url_string)
        @url = URI(base_url_string + "/v1/version")
        @logger = ChefLicensing::Config.logger
      end

      # Ping Airgap is "detected" if the host is unreachable in an HTTP sense.
      def detected?
        return @status unless @status.nil?

        Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
          http.open_timeout = 5

          request = Net::HTTP::Get.new url
          response = http.request request # Net::HTTPResponse object
          @status = !(response.is_a? Net::HTTPSuccess)
        end
        @status

      rescue => exception
        @logger.debug "Airgap ping failed.\n#{exception.message}\nAssuming airgap mode is on."
        @status = true
      end
    end
  end
end
