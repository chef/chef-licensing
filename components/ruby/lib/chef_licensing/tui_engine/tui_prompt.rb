require "timeout" unless defined?(Timeout)
require "tty-prompt"
require "logger"
require_relative "tui_exceptions"

module ChefLicensing
  class TUIEngine
    class TUIPrompt
      attr_accessor :next_interaction_id, :processed_input, :output, :input, :logger, :tty_prompt

      def initialize(opts = {})
        @output = opts[:output] || STDOUT
        @input = opts[:input] || STDIN
        @logger = opts[:logger] || Logger.new(STDOUT)
        @tty_prompt = TTY::Prompt.new(track_history: false, active_color: :bold, interrupt: :exit, output: output, input: input)
      end

      # TBD: Add comments for each prompt type briefly.

      def yes(messages)
        message = messages.is_a?(Array) ? messages[0] : messages

        @tty_prompt.yes?(message, default: true)
      end

      def say(messages)
        message = messages.is_a?(Array) ? messages[0] : messages
        @tty_prompt.say(message)
      end

      def ok(messages)
        message = messages.is_a?(Array) ? messages[0] : messages
        @tty_prompt.ok(message)
      end

      def warn(messages)
        message = messages.is_a?(Array) ? messages[0] : messages
        @tty_prompt.warn(message)
      end

      def error(messages)
        message = messages.is_a?(Array) ? messages[0] : messages
        @tty_prompt.error(message)
      end

      def select(messages)
        header = messages[0]
        choices_list = messages[1]
        @tty_prompt.select(header, choices_list)
      end

      def enum_select(messages)
        @tty_prompt.enum_select(messages[0], messages[1])
      end

      def ask(messages)
        message = messages.is_a?(Array) ? messages[0] : messages
        @tty_prompt.ask(message)
      end
    end
  end
end
