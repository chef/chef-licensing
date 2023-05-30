require_relative "tui_prompt"
require_relative "tui_actions"
require "erb" unless defined?(Erb)
require_relative "../config"
require "pastel" unless defined?(Pastel)

module ChefLicensing
  class TUIEngine
    class TUIEngineState < Hash
      attr_accessor :next_interaction_id, :input, :logger, :prompt, :tui_actions

      def initialize(opts = {})
        @input = {}
        # store the pastel key for enabling styled messages in the yaml file
        @input[:pastel] = Pastel.new
        @logger = ChefLicensing::Config.logger
        @prompt = ChefLicensing::TUIEngine::TUIPrompt.new(opts)
        @tui_actions = ChefLicensing::TUIEngine::TUIActions.new(opts)
      end

      def default_action(interaction)
        logger.debug "Default action called for interaction id: #{interaction.id}"

        response = if interaction.messages
                     messages = render_messages(interaction.messages)
                     @prompt.send(interaction.prompt_type, messages, interaction.prompt_attributes)
                   elsif interaction.action
                     @tui_actions.send(interaction.action, @input)
                   end

        @input.store(interaction.id, response)
        logger.debug "Response for interaction #{interaction.id} is #{@input[interaction.id]}"

        @next_interaction_id = if interaction.paths.size > 1
                                 interaction.response_path_map[response.to_s]
                               elsif interaction.paths.size == 1
                                 interaction.paths.keys.first
                               end
      end

      def append_info_to_input(extra_info_hash)
        @input.merge!(extra_info_hash)
      end

      private

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
