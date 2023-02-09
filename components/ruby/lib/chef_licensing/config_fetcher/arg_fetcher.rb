module ChefLicensing
  class ArgFetcher

    def initialize(argv = ARGV)
      @argv = argv
    end

    def fetch_value(arg_name, arg_type = :string)
      case arg_type
      when :boolean
        @argv.include?(arg_name)
      when :string
        # TODO: Refactor this code to use some library in near future
        # There were some issues with OptionParser, so we are using this
        # custom code for now.

        # Currently, we are supporting two ways of passing arguments:
        # 1. --chef-license-server foo
        # 2. --chef-license-server=foo

        # Check if argument is passed as: --chef-license-server foo
        arg_value = @argv.include?(arg_name) ? @argv[@argv.index(arg_name) + 1] : nil

        # Check if argument is passed as: --chef-license-server=foo
        # only if arg_value is nil
        if arg_value.nil?
          arg_value = @argv.select { |arg| arg.start_with?("#{arg_name}=") }.first
          arg_value = arg_value.split("=").last if arg_value
        end
        arg_value
      end
    end

    def self.fetch_value(arg_name, arg_type = :string)
      new.fetch_value(arg_name, arg_type)
    end
  end
end
