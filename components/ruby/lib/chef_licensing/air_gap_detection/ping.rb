require "net/http" unless defined?(Net::HTTP)

module ChefLicensing
  class AirGapDetection
    class Ping

      # If status is true, airgap mode is on - we are isolated.
      attr_reader :url, :status

      def initialize(base_url_string)
        @url = URI(base_url_string + "/v1/version")
      end

      # Ping Airgap is "detected" if the host is unreachable in an HTTP sense.
      def detected?
        return @status unless @status.nil?

        Net::HTTP.start(url.host, url.port, :use_ssl => true) do |http|
          http.open_timeout = 5

          request = Net::HTTP::Get.new url
          response = http.request request # Net::HTTPResponse object
          @status = !(response.is_a? Net::HTTPSuccess)
        end
        @status

      rescue => exception
        # TODO: Wish I had a logger here for exception.message
        return @status = true
      end
    end
  end
end
