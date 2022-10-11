module ChefLicensing
  class TUIEngine
    class TUIPrompt
      def say(messages)
        msg = @all_messages[messages[0].to_sym]
        @tty_prompt.say(msg)
      end

      def ok(messages)
        @tty_prompt.ok(messages)
      end

      def warn(messages)
        @tty_prompt.warn(messages)
      end

      def error(messages)
        @tty_prompt.error(messages)
      end
    end
  end
end