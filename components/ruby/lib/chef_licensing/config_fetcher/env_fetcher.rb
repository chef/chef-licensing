module ChefLicensing
  class EnvFetcher

    attr_accessor :env

    def initialize(env)
      @env = env
    end

    def fetch_value(env_name, env_type = :string)
      case env_type
      when :boolean
        env.key?(env_name)
      when :string
        env.fetch(env_name, nil)
      end
    end
  end
end
