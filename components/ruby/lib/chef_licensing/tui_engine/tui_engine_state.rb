require "logger"
require_relative "tui_prompt"
require_relative "tui_actions"
require "erb" unless defined?(Erb)

module ChefLicensing
  class TUIEngine
    class TUIEngineState < Hash
      attr_accessor :next_interaction_id, :input, :logger, :prompt, :tui_actions

      def initialize(opts = {})
        @input = {}
        @cl_config = opts[:cl_config] || ChefLicensing::Config.instance
        @logger = cl_config.logger
        @prompt = ChefLicensing::TUIEngine::TUIPrompt.new(opts)
        @tui_actions = ChefLicensing::TUIEngine::TUIActions.new
      end

      def default_action(interaction)
        # Style is pending.

        logger.debug "Default action called for interaction id: #{interaction.id}"

        if interaction.messages
          messages = render_messages(interaction.messages)
          response = @prompt.send(interaction.prompt_type, messages, interaction.prompt_attributes)
        elsif interaction.action
          response = @tui_actions.send(interaction.action, @input)
        end

        @input.store(interaction.id, response)

        logger.debug "Response for interaction #{interaction.id} is #{@input[interaction.id]}"

        if interaction.paths.size > 1
          @next_interaction_id = interaction.response_path_map[response.to_s]
        elsif interaction.paths.size == 1
          @next_interaction_id = interaction.paths.keys.first
        else
          @next_interaction_id = nil
        end
      end

      private

      attr_reader :cl_config

      def erb_result(message)
        ERB.new(message).result_with_hash(input: input)
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
