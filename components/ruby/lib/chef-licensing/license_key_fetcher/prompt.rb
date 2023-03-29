require_relative "../tui_engine"

module ChefLicensing
  class LicenseKeyFetcher
    class Prompt
      attr_accessor :config, :tui_engine, :license_type

      def initialize(config = {})
        @config = config
        initialize_tui_engine
      end

      def fetch
        # Here info is a hash of { interaction_id: response }
        info = tui_engine.run_interaction(config[:start_interaction])

        # The interaction_id ask_for_license_id holds the license key
        # TODO: Do we move this to tui_engine?
        if info[:fetch_license_id].nil?
          []
        else
          self.license_type = info[:license_type]
          [info[:fetch_license_id]]
        end
      end

      def append_info_to_tui_engine(extra_info_hash)
        tui_engine.append_info_to_input(extra_info_hash)
      end

      private

      def initialize_tui_engine
        # use the default interaction file if interaction_file is nil
        if config[:interaction_file].nil?
          interaction_file_path = ::File.join(::File.dirname(__FILE__), "chef_licensing_interactions.yaml")
          @config.store(:interaction_file, interaction_file_path)
        end
        @tui_engine = ChefLicensing::TUIEngine.new(@config)
      end
    end
  end
end
