require "net/http"

module ChefLicensing
  class AirGap
    class Ping

      attr_reader :host, :status

      def initialize(host)
        @host = URI(host)
      end

      def verify_ping
        return @status if @status

        response = Net::HTTP.get_response(host)
        @status = response.is_a? Net::HTTPSuccess
        @status
      rescue => exception
        warn "Unable to ping #{host}.\n#{exception.message}"
      end
    end
  end
end
