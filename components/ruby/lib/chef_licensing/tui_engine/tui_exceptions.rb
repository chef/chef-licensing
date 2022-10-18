require "timeout" unless defined?(Timeout)

module ChefLicensing
  class TUIEngine
    class YAMLException < StandardError
    end

    class PromptTimeout < Timeout::Error; end

    class IncompleteFlowException < StandardError; end
  end
end
