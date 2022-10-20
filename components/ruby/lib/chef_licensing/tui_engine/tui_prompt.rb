require "timeout" unless defined?(Timeout)
require "tty-prompt"
require "logger"
require_relative "tui_exceptions"
require "erb" unless defined?(Erb)

module ChefLicensing
  class TUIEngine
    class TUIPrompt
      attr_accessor :output, :input, :logger, :tty_prompt

      def initialize(opts = {})
        @output = opts[:output] || STDOUT
        @input = opts[:input] || STDIN
        @logger = opts[:logger] || Logger.new(opts.key?(:output) ? opts[:output] : STDERR)
        @tty_prompt = TTY::Prompt.new(track_history: false, active_color: :bold, interrupt: :exit, output: output, input: input)
      end

      # TBD: Add comments for each prompt type briefly.

      # yes prompts the user with a yes/no question and returns true if the user
      # answers yes and false if the user answers no.
      def yes(messages, prompt_attributes)
        messages = render_messages(messages)
        message = messages.is_a?(Array) ? messages[0] : messages

        @tty_prompt.yes?(message)
      end

      # say prints the given message to the output stream.
      # default prompt_type is say.
      def say(messages, prompt_attributes)
        messages = render_messages(messages)
        message = messages.is_a?(Array) ? messages[0] : messages
        @tty_prompt.say(message)
      end

      # ok prints the given message to the output stream in green color.
      def ok(messages, prompt_attributes)
        messages = render_messages(messages)
        message = messages.is_a?(Array) ? messages[0] : messages
        @tty_prompt.ok(message)
      end

      # warn prints the given message to the output stream in yellow color.
      def warn(messages, prompt_attributes)
        messages = render_messages(messages)
        message = messages.is_a?(Array) ? messages[0] : messages
        @tty_prompt.warn(message)
      end

      # error prints the given message to the output stream in red color.
      # prompt_attributes = {} is added to extend the prompt in future.
      def error(messages, prompt_attributes)
        messages = render_messages(messages)
        message = messages.is_a?(Array) ? messages[0] : messages
        @tty_prompt.error(message)
      end

      # select prompts the user to select an option from a list of options.
      # prompt_attributes = {} is added to extend the prompt in future.
      def select(messages, prompt_attributes)
        messages = render_messages(messages)
        header = messages[0]
        choices_list = messages[1]
        @tty_prompt.select(header, choices_list)
      end

      # enum_select prompts the user to select an option from a list of options.
      # prompt_attributes = {} is added to extend the prompt in future.
      def enum_select(messages, prompt_attributes)
        messages = render_messages(messages)
        @tty_prompt.enum_select(messages[0], messages[1])
      end

      # ask prompts the user to enter a value.
      # prompt_attributes = {} is added to extend the prompt in future.
      def ask(messages, prompt_attributes)
        messages = render_messages(messages)
        message = messages.is_a?(Array) ? messages[0] : messages
        @tty_prompt.ask(message)
      end

      # timeout_yes prompt wraps yes prompt with timeout.
      def timeout_yes(messages, prompt_attributes)
        messages = render_messages(messages)
        prompt_attributes.transform_keys!(&:to_sym)
        timeout_duration = prompt_attributes[:timeout_duration] || 60

        Timeout.timeout(timeout_duration, PromptTimeout) do
          yes(messages, prompt_attributes)
        rescue PromptTimeout => e
          error(prompt_attributes[:timeout_message] || "Prompt Timeout", prompt_attributes)
          # Qs: Why do we unsubscribe from the tty_prompt here?
          @tty_prompt.unsubscribe(@tty_prompt.reader)
          logger.error("Timeout error: #{e}")
          exit!
        end
      end

      private

      def erb_result(message)
        ERB.new(message).result(binding)
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
