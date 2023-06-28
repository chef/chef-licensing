begin
  require "mixlib/cli" unless defined?(Mixlib::CLI)
rescue
  raise "Must have mixlib-cli gem installed to use this mixin"
end

module ChefLicensing
  module CLIFlags

    module MixlibCLI

      def self.included(klass)
        # TBD need to confirm the name of the option
        klass.option :chef_license_key,
          long: "--chef-license-key KEY",
          description: "Add a new Chef License Key to the license store. Ignores duplicates (not applicable to local licensing service)",
          required: false

        klass.option :chef_license_server,
          long: "--chef-license-server URL",
          description: "Add a custom Chef License Server URL. Overrides the global license server URL.",
          required: false
      end

    end

  end
end
