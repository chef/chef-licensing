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
        messages_yaml = opts[:messages_yaml] || File.join(File.dirname(__FILE__), "yaml/default_messages.yaml")
        @all_messages = read_messages_from_yaml(messages_yaml)
        @all_messages.transform_keys!(&:to_sym)
      end

      def yes(messages)
        msg = @all_messages[messages[0].to_sym]
        @tty_prompt.yes?(msg, default: true)
      end

      def say(messages)
        msg = @all_messages[messages[0].to_sym]
        @tty_prompt.say(msg)
      end

      def ok(messages)
        msg = @all_messages[messages[0].to_sym]
        @tty_prompt.ok(msg)
      end

      def warn(messages)
        msg = @all_messages[messages[0].to_sym]
        @tty_prompt.warn(msg)
      end

      def error(messages)
        msg = @all_messages[messages[0].to_sym]
        @tty_prompt.error(msg)
      end

      def select(messages)
        header = @all_messages[messages[0].to_sym]

        choices_list = []
        choices_map = {}

        # TODO: Improve the comments.

        # Why are we doing this?
        # @all_messages is the hash of all key-values from the messages.yaml file.
        # messages has the keys of the text we want to display to the user.
        # we want to display the values to the keys given in messages; hence choices_list
        # but we want to return the key of the text the user selects; hence choices_map
        messages[1].map do |message|
          choices_list.push(@all_messages[message.to_sym])
          choices_map[message.to_sym] = @all_messages[message.to_sym]
        end

        response = @tty_prompt.select(header, choices_list)

        # returns the key of the text the user selected
        # this response key is mapped to the next interaction id in the response_path_map
        choices_map.key(response)
      end

      def enum_select(messages)
        @tty_prompt.enum_select(messages[0], messages[1])
      end

      def ask(messages)
        msg = @all_messages[messages[0].to_sym]
        # @tty_prompt.ask(msg, prompt_attributes)
        response = @tty_prompt.ask(msg) do |q|
          prompt_attributes.each do |k, v|
            q.send(k, v)
          end
        end
      end

      private

      def read_messages_from_yaml(messages_yaml)
        require "yaml" unless defined?(YAML)
        YAML.load_file(messages_yaml)
      rescue => e
        raise ChefLicensing::TUIEngine::YAMLException, "Unable to load yaml file. #{e.message}"
      end
    end
  end
end
