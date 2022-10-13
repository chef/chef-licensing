require "timeout" unless defined?(Timeout)
require "tty-prompt"
require "logger"
require_relative "tui_prompt"
require_relative "../license_key_validator"
require_relative "../exceptions/invalid_license"
require_relative "tui_actions"
module ChefLicensing
  class TUIEngine
    class TUIEngineState < Hash
      attr_accessor :next_interaction_id, :processed_input, :logger, :prompt, :tui_actions

      def initialize(opts = {})
        @processed_input = {}
        @logger = opts[:logger] || Logger.new(STDERR)
        @prompt = ChefLicensing::TUIEngine::TUIPrompt.new(opts)
        @tui_actions = ChefLicensing::TUIEngine::TUIActions.new
      end

      def default_action(interaction)
        # Style is pending.

        # We need to display only if the interaction has messages.
        # When a prompt_type is not given, we assume it to be say.
        if interaction.messages && @prompt.respond_to?(interaction.prompt_type)
          response = @prompt.send(interaction.prompt_type, interaction.messages)
          @processed_input.store(interaction.id, response)
        end

        # We need to call the action only if the interaction has an action.
        if interaction.action && @tui_actions.respond_to?(interaction.action)
          response = @tui_actions.send(interaction.action, interaction)
          @processed_input.store(interaction.id, response)
        end

        if interaction.paths.size > 1
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