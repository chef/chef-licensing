require "timeout" unless defined?(Timeout)
require "tty-prompt"
require_relative "tui_exceptions"
require "erb" unless defined?(Erb)
require_relative "../config"

module ChefLicensing
  class TUIEngine
    class TUIPrompt
      attr_accessor :output, :input, :logger, :tty_prompt

      def initialize(opts = {})
        @output = ChefLicensing::Config.output
        @input = opts[:input] || STDIN
        @logger = ChefLicensing::Config.logger
        @tty_prompt = opts[:prompt] || TTY::Prompt.new(track_history: false, active_color: :bold, interrupt: :exit, output: output, input: input)
      end

      # yes prompts the user with a yes/no question and returns true if the user
      # answers yes and false if the user answers no.
      # prompt_attributes is added to extend the prompt in future.
      def yes(messages, prompt_attributes)
        message = Array(messages).first
        @tty_prompt.yes?(message)
      end

      # say prints the given message to the output stream.
      # default prompt_type of an interaction is say.
      # prompt_attributes is added to extend the prompt in future.
      def say(messages, prompt_attributes)
        message = Array(messages).first
        @tty_prompt.say(message)
      end

      # ok prints the given message to the output stream in green color.
      # prompt_attributes is added to extend the prompt in future.
      def ok(messages, prompt_attributes)
        message = Array(messages).first
        @tty_prompt.ok(message)
      end

      # warn prints the given message to the output stream in yellow color.
      # prompt_attributes is added to extend the prompt in future.
      def warn(messages, prompt_attributes)
        message = Array(messages).first
        @tty_prompt.warn(message)
      end

      # error prints the given message to the output stream in red color.
      # prompt_attributes is added to extend the prompt in future.
      def error(messages, prompt_attributes)
        message = Array(messages).first
        @tty_prompt.error(message)
      end

      # select prompts the user to select an option from a list of options.
      # prompt_attributes is added to extend the prompt in future.
      def select(messages, prompt_attributes)
        header, choices_list = fetch_header_and_choices(messages, :select)
        @tty_prompt.select(header, choices_list)
      end

      # enum_select prompts the user to select an option from a list of options.
      # prompt_attributes is added to extend the prompt in future.
      def enum_select(messages, prompt_attributes)
        header, choices_list = fetch_header_and_choices(messages, :enum_select)
        @tty_prompt.enum_select(header, choices_list)
      end

      # ask prompts the user to enter a value.
      # prompt_attributes is added to extend the prompt in future.
      def ask(messages, prompt_attributes)
        message = Array(messages).first
        @tty_prompt.ask(message)
      end

      # timeout_yes prompt wraps yes prompt with timeout.
      # prompt_attributes is added to extend the prompt in future.
      def timeout_yes(messages, prompt_attributes)
        timeout_helper(messages, method(:yes), prompt_attributes)
      end

      def timeout_select(messages, prompt_attributes)
        timeout_helper(messages, method(:select), prompt_attributes)
      end

      def silent(messages, prompt_attributes)
        Array(messages).first
      end

      private

      def fetch_header_and_choices(messages, prompt_type)
        unless messages.is_a?(Array) && messages.size > 1
          raise ChefLicensing::TUIEngine::BadPromptInput, "messages for #{prompt_type} must be an array of size greater than 1"
        end

        header, *choices_list = messages
        [header, choices_list]
      end

      def timeout_helper(messages, prompt_method, prompt_attributes)
        prompt_attributes.transform_keys!(&:to_sym)
        timeout_duration = prompt_attributes[:timeout_duration] || 60
        Timeout.timeout(timeout_duration, PromptTimeout) do
          prompt_method.call(messages, prompt_attributes)
        rescue PromptTimeout
          error(prompt_attributes[:timeout_message] || "Prompt Timeout", prompt_attributes)
          @tty_prompt.unsubscribe(@tty_prompt.reader)
          # TODO: Exit with a meaningful error code.
          output.puts "Timed out!"
          exit
        end
      end
    end
  end
end
