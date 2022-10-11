module ChefLicensing
  class TUIEngine
    class TUIPrompt
      def ask(message)
        @tty_prompt.ask(message)
      end
    end
  end
end