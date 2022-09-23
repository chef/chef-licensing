require "net/ping"

module ChefLicensing
  class AirGap
    class Ping

      attr_reader :host

      def initialize(host)
        @host = host
      end

      def verify_ping
        check = Net::Ping::External.new(host)
        check.ping?
        raise AirGapException, "Unable to ping public chef server.\nPlease check your internet connectivity." unless check.ping?
      end
    end
  end
end