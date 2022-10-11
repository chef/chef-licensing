require "timeout" unless defined?(Timeout)
require "tty-prompt"
require "logger"
require_relative "prompts/prompts"
require_relative "exceptions/tui_exceptions"

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
