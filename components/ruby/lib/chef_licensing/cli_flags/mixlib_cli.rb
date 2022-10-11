begin
  require "mixlib/cli" unless defined?(Mixlib::CLI)
rescue
  raise "Must have mixlib-cli gem installed to use this mixin"
end

module ChefLicensing
  module CLIFlags

    module MixlibCLI

      def self.included(klass)
        # TBD need to confirm the name of the key
        klass.option :chef_license_key,
          long: "--chef-license-key KEY",
          description: "Accepts the license key",
          required: false
      end

    end

  end
end
