begin
  require "thor" unless defined?(Thor)
rescue
  raise "Must have thor gem installed to use this mixin"
end

module ChefLicensing
  module CLIFlags
    module Thor
      def self.included(klass)
        # TBD need to confirm the name of the option
        klass.class_option :chef_license_key,
          type: :string,
          desc: "Add a new Chef License Key to the license store. Ignores duplicates."
      end
    end
  end
end
