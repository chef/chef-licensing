require "timeout" unless defined?(Timeout)

module ChefLicensing
  class TUIEngine
    class YAMLException < StandardError
    end

    class PromptTimeout < Timeout::Error; end
  end
end