module ChefLicensing
  class EnvFetcher

    def initialize(env = ENV)
      @env = env
    end

    def fetch_value(env_name, env_type = :string)
      case env_type
      when :boolean
        @env.key?(env_name)
      when :string
        @env.fetch(env_name, nil)
      end
    end

    def self.fetch_value(env_name, env_type = :string)
      new.fetch_value(env_name, env_type)
    end
  end
end
