module ChefLicensing
  class Config
    class << self
      attr_accessor :licensing_server
      attr_writer :logger

      def logger
        @logger || Logger.new($stdout)
      end
    end

    LICENSING_SERVER = self.licensing_server ||= ENV.fetch("CHEF_LICENSING_SERVER", "https://licensing.chef.co/License")
  end
end
