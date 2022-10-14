# The prompt.rb needs to be removed; or tui_prompt.rb could be renamed to prompt.rb
require_relative "../tui_engine/tui_engine"

module ChefLicensing
  class LicenseKeyFetcher
    class TUIPrompt
      attr_accessor :config

      def initialize(config = {})
        @config = config
      end

      def fetch
        interaction_file_path = ::File.join(::File.dirname(__FILE__), "chef_licensing_interactions.yaml")
        @config.store(:interaction_file, interaction_file_path)
        tui_engine = ChefLicensing::TUIEngine.new(@config)
        info = tui_engine.run_interaction

        if info[:ask_for_license_id].nil?
          puts "Failed to obtain license."
          exit
        else
          info[:ask_for_license_id]
        end
      end
    end
  end
end
