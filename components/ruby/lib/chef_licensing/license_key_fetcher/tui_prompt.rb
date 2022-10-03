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
        # Currently default.yaml is used for testing purposes.
        tui_engine = ChefLicensing::TUIEngine.new(@config)
        data = tui_engine.run_interaction
        data[:license_id] unless data[:license_id].nil? || data[:license_id_valid] == false
      end
    end
  end
end
