module ChefLicensing
  class EnvFetcher
    def self.fetch_value(env_name, env_type = :string)
      case env_type
      when :boolean
        ENV.key?(env_name)
      when :string
        ENV.fetch(env_name, nil)
      end
    end
  end
end
