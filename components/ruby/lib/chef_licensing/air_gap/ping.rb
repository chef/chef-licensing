require "net/http"

module ChefLicensing
  class AirGap
    class Ping

      attr_reader :host, :status

      def initialize(host)
        @host = URI(host)
      end

      def verify_ping
        return @status if @status.is_a? Net::HTTPSuccess

        @status = Net::HTTP.get_response(host)

        raise "Error message: #{@status.message}\nStatus code: #{@status.code}" unless @status.is_a? Net::HTTPSuccess
      rescue => exception
        raise AirGapException, "Unable to ping public licensing server.\n#{exception.message}"
      end
    end
  end
end
