require_relative "../tui_engine"

module ChefLicensing
  class LicenseKeyFetcher
    class Prompt
      attr_accessor :config

      def initialize(config = {})
        @config = config
      end

      def fetch
        interaction_file_path = ::File.join(::File.dirname(__FILE__), "chef_licensing_interactions.yaml")
        @config.store(:interaction_file, interaction_file_path)
        tui_engine = ChefLicensing::TUIEngine.new(@config)

        # Here info is a hash of { interaction_id: response }
        info = tui_engine.run_interaction

        # The interaction_id ask_for_license_id holds the license key
        # TODO: Do we move this to tui_engine?
        if info[:ask_for_license_id].nil?
          # puts "Failed to obtain license."
          exit
        else
          [info[:ask_for_license_id]]
        end
      end
    end
  end
end
