begin
  require "thor" unless defined?(Thor)
rescue
  raise "Must have thor gem installed to use this mixin"
end

module ChefLicensing
  module CLIFlags
    module Thor
      def self.included(klass)
        # TBD need to confirm the name of the key
        klass.class_option :chef_license_key,
          type: :string,
          desc: "Accept the license for this product and any contained products: accept, accept-no-persist, accept-silent"
      end
    end
  end
end