require "net/http" unless defined?(Net::HTTP)

module ChefLicensing
  class AirGap
    class Ping

      attr_reader :url, :status

      def initialize(url)
        @url = URI(url)
      end

      def verify_ping
        return @status if @status

        response = Net::HTTP.get_response(url)
        @status = response.is_a? Net::HTTPSuccess
        @status
      rescue => exception
        warn "Unable to ping #{url}.\n#{exception.message}"
      end
    end
  end
end
