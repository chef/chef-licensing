require "timeout" unless defined?(Timeout)
require "tty-prompt"

module ChefLicensing
  class TUIEngine
    class TUIEngineState < Hash
      attr_accessor :next_interaction_id, :processed_input

      def initialize
        @processed_input = {}
      end

      def initial_greet_fn(interaction)
        puts interaction.messages
        @next_interaction_id = "question_about_license_id"
      end

      def question_about_license_id_fn(interaction)
        prompt = TTY::Prompt.new(track_history: false, active_color: :bold, interrupt: :exit)

        begin
          Timeout.timeout(10, ChefLicensing::TUIEngine::PromptTimeout) do
            answer = prompt.yes?(interaction.messages, default: true)
            @processed_input.store("answer".to_sym, answer)
            @next_interaction_id = answer ? "ask_input_for_license_id" : "ask_for_license_generation"
          end
        rescue ChefLicensing::TUIEngine::PromptTimeout
          prompt.unsubscribe(prompt.reader)
          @next_interaction_id = "prompt_timeout_exit"
        end
      end

      def ask_input_for_license_id_fn(interaction)
        # TODO: Add (..., output: output, input: input) to TTY::Prompt.new
        puts interaction.messages[0]
        prompt = TTY::Prompt.new(track_history: false, active_color: :bold, interrupt: :exit)

        # TODO: Change q.validate to an actual regex that matches the license id format
        license_id = prompt.ask(interaction.messages[1]) do |q|
          q.required true
          q.validate(/\d{8}/)
        end

        @processed_input.store("license_id".to_sym, license_id)
        @next_interaction_id = "validate_license_id"
      end

      def validate_license_id_fn(interaction)
        # TODO: Do an actual validation with the license id validation API
        @processed_input.store("license_id_valid".to_sym, true)
        @next_interaction_id = "validation_success"

        # TODO: Set @next_interaction_id to "validation_failure" if the license id is invalid
        # and set @processed_input.store("license_id_valid".to_sym, false)
      end

      def validation_success_fn(interaction)
        puts interaction.messages
        @next_interaction_id = "exit_license_tui"
      end

      def validation_failure_fn(interaction)
        puts interaction.messages
        @next_interaction_id = "ask_input_for_license_id"
      end

      def ask_for_license_generation_fn(interaction)
        puts interaction.messages
        @next_interaction_id = "exit_license_tui"
      end

      def exit_license_tui_fn(interaction)
        puts interaction.messages
        @next_interaction_id = nil
      end

      def prompt_timeout_exit_fn(interaction)
        puts interaction.messages
        @next_interaction_id = nil
      end
    end
  end
end