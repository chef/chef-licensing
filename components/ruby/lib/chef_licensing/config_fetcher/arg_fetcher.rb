module ChefLicensing
  class ArgFetcher

    class Boolean

      attr_accessor :value, :arg_name

      def initialize(arg_name)
        @arg_name = arg_name
        @value = ARGV.include?(@arg_name)
      end
    end

    class String

      attr_accessor :value, :arg_name

      def initialize(arg_name)
        @arg_name = arg_name
        # TODO: Discuss with the team if we need to support:
        # --arg_name=value or --arg_name value or both
        @value = ARGV.include?(@arg_name) ? ARGV[ARGV.index(@arg_name) + 1] : nil
      end
    end
  end
end
