require "timeout" unless defined?(Timeout)
require "tty-prompt"
require "logger"
require_relative "tui_prompt"
require_relative "../license_key_validator"
require_relative "../exceptions/invalid_license"

module ChefLicensing
  class TUIEngine
    class TUIEngineState < Hash
      attr_accessor :next_interaction_id, :processed_input, :logger, :prompt

      def initialize(opts = {})
        @processed_input = {}
        @logger = opts[:logger] || Logger.new(STDERR)
        @prompt = ChefLicensing::TUIEngine::TUIPrompt.new(opts)
      end

      def default_action(interaction)
        # Style is pending.

        response = @prompt.send(interaction.prompt_type, interaction.messages) if @prompt.respond_to?(interaction.prompt_type) && interaction.messages
        @processed_input.store(interaction.id, response)

        # TBD: Actions are pending.
        send(interaction.action, interaction) if interaction.action && respond_to?(interaction.action)

        if interaction.paths.size > 1
          # There can be situations where the next path can be determined based on
          # action item of the interaction.
          @next_interaction_id = interaction.response_path_map[response.to_s]
        elsif interaction.paths.size == 1
          @next_interaction_id = interaction.paths.keys.first
        else
          @next_interaction_id = nil
        end
      end
    end
  end
end