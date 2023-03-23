require "timeout" unless defined?(Timeout)

module ChefLicensing
  class TUIEngine
    class BadInteractionFile < StandardError; end

    class PromptTimeout < Timeout::Error; end

    class IncompleteFlowException < StandardError; end

    class UnsupportedInteractionFileFormat < StandardError; end

    class MissingInteractionFile < StandardError; end

    class BadPromptInput < StandardError; end
  end
end
