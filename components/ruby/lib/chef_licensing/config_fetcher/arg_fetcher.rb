module ChefLicensing
  class ArgFetcher

    attr_accessor :argv

    def initialize(argv)
      @argv = argv
    end

    def fetch_value(arg_name, arg_type = :string)
      # TODO: Change to use OptionParser
      case arg_type
      when :boolean
        argv.include?(arg_name)
      when :string
        argv.include?(arg_name) ? argv[argv.index(arg_name) + 1] : nil
      end
    end
  end
end
