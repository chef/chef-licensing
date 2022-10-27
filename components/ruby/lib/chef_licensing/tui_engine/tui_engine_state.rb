require "logger"
require_relative "tui_prompt"
require_relative "tui_actions"
require "erb" unless defined?(Erb)

module ChefLicensing
  class TUIEngine
    class TUIEngineState < Hash
      attr_accessor :next_interaction_id, :processed_input, :logger, :prompt, :tui_actions

      def initialize(opts = {})
        @processed_input = {}
        @logger = opts[:logger] || Logger.new(opts.key?(:output) ? opts[:output] : STDERR)
        @prompt = ChefLicensing::TUIEngine::TUIPrompt.new(opts)
        @tui_actions = ChefLicensing::TUIEngine::TUIActions.new
      end

      def default_action(interaction)
        # Style is pending.

        logger.debug "Default action called for interaction id: #{interaction.id}"

        if interaction.messages
          response = @prompt.send(interaction.prompt_type, interaction.messages, interaction.prompt_attributes)
        elsif interaction.action
          response = @tui_actions.send(interaction.action, @processed_input)
        end

        @processed_input.store(interaction.id, response)

        logger.debug "Response for interaction #{interaction.id} is #{@processed_input[interaction.id]}"

        if interaction.paths.size > 1
          @next_interaction_id = interaction.response_path_map[response.to_s]
        elsif interaction.paths.size == 1
          @next_interaction_id = interaction.paths.keys.first
        else
          @next_interaction_id = nil
        end
      end

      private

      def erb_result(message)
        ERB.new(message).result_with_hash(processed_input: processed_input)
      end

      def render_messages(messages)
        if messages.is_a?(String)
          erb_result(messages)
        elsif messages.is_a?(Array)
          messages.map do |message|
            render_messages(message)
          end
        end
      end
    end
  end
end
