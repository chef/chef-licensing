require "timeout" unless defined?(Timeout)
require "tty-prompt"
require "logger"
require_relative "../license_key_validator"
require_relative "../exceptions/invalid_license"

module ChefLicensing
  class TUIEngine
    class TUIEngineState < Hash
      attr_accessor :next_interaction_id, :processed_input, :output, :input, :logger, :tty_prompt

      def initialize(opts = {})
        @processed_input = {}
        @output = opts[:output] || STDOUT
        @input = opts[:input] || STDIN
        @logger = opts[:logger] || Logger.new(STDOUT)
        @tty_prompt = TTY::Prompt.new(track_history: false, active_color: :bold, interrupt: :exit, output: output, input: input)
      end

      def initial_greet_fn(interaction)
        output.puts interaction.messages
        @next_interaction_id = "question_about_license_id"
      end

      def question_about_license_id_fn(interaction)
        begin
          Timeout.timeout(10, ChefLicensing::TUIEngine::PromptTimeout) do
            answer = @tty_prompt.yes?(interaction.messages, default: true)
            @processed_input.store("answer".to_sym, answer)
            @next_interaction_id = answer ? "ask_input_for_license_id" : "ask_for_license_generation"
          end
        rescue ChefLicensing::TUIEngine::PromptTimeout
          @tty_prompt.unsubscribe(@tty_prompt.reader)
          @next_interaction_id = "prompt_timeout_exit"
        end
      end

      def ask_input_for_license_id_fn(interaction)
        output.puts interaction.messages[0]

        # TODO: Change q.validate to an actual regex that matches the license id format
        license_id = @tty_prompt.ask(interaction.messages[1]) do |q|
          q.required true
          # q.validate(/\d{8}/)
        end

        @processed_input.store("license_id".to_sym, license_id)
        @next_interaction_id = "validate_license_id"
      end

      def validate_license_id_fn(interaction)
        output.puts "License ID: #{@processed_input[:license_id]} is being validated."
        status = ChefLicensing::LicenseKeyValidator.validate!(@processed_input[:license_id])
        @processed_input.store("license_id_valid".to_sym, status)
        @next_interaction_id = "validation_success"
      rescue ChefLicensing::InvalidLicense => e
        output.puts e.message
        @next_interaction_id = "validation_failure"
        @processed_input.store("license_id_valid".to_sym, false)
      end

      def validation_success_fn(interaction)
        output.puts interaction.messages
        @next_interaction_id = "exit_license_tui"
      end

      def validation_failure_fn(interaction)
        output.puts interaction.messages
        @next_interaction_id = "ask_input_for_license_id"
      end

      def ask_for_license_generation_fn(interaction)
        output.puts interaction.messages

        # Currently the license generation is not implemented.
        # So, we are directly storing a dummy license id in the processed_input.
        @processed_input.store("license_id".to_sym, "87654321")
        @processed_input.store("license_id_valid".to_sym, true)
        @next_interaction_id = "exit_license_tui"
      end

      def exit_license_tui_fn(interaction)
        output.puts interaction.messages
        @next_interaction_id = nil
      end

      def prompt_timeout_exit_fn(interaction)
        output.puts interaction.messages
        @next_interaction_id = nil
      end
    end
  end
end