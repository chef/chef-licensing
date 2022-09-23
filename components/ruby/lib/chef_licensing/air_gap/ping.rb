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
        raise AirGapException, "Unable to ping public licensing server.\nPlease check your internet connectivity." unless check.ping?
      end
    end
  end
end