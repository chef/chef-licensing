module ChefLicensing
  class EnvFetcher

    class Boolean
      attr_accessor :value, :env_name

      def initialize(env_name)
        @env_name = env_name
        @value = ENV.key?(@env_name)
      end
    end

    class String
      attr_accessor :value, :env_name

      def initialize(env_name)
        @env_name = env_name
        @value = ENV.key?(@env_name) ? ENV[@env_name] : nil
      end
    end
  end
end
