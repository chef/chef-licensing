require "net/http" unless defined?(Net::HTTP)

module ChefLicensing
  class AirGap
    class Ping

      # If status is true, airgap mode is on - we are isolated.
      attr_reader :url, :status

      def initialize(base_url_string)
        @url = URI(base_url_string + "/v1/version")
      end

      # Ping Airgap is "enabled" if the host is unreachable in an HTTP sense.
      def enabled?
        return @status if @status

        response = Net::HTTP.get_response(url)
        @status = !(response.is_a? Net::HTTPSuccess)
        @status
      rescue => exception
        warn "Unable to ping #{url}.\n#{exception.message}"
      end
    end
  end
end
