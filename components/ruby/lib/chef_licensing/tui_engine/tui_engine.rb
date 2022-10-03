require_relative "tui_exceptions"
require_relative "tui_interaction"
require_relative "tui_engine_state"

module ChefLicensing
  class TUIEngine
    attr_accessor :yaml_data, :tui_interactions, :opts
    def initialize(opts = {})
      yaml_file = opts[:yaml_file] || File.join(File.dirname(__FILE__), "default.yaml")
      @yaml_data = inflate_yaml_data(yaml_file)
      @tui_interactions = {}
      get_interaction_objects
      build_interaction_path
      # opts is a hash of { :yaml_file => <yaml_file>, :input => <input>, :output => <output>, :logger => <logger> }
      @opts = opts
    end

    def inflate_yaml_data(yaml_file)
      require "yaml" unless defined?(YAML)
      YAML.load_file(yaml_file)
    rescue => e
      raise ChefLicensing::TUIEngine::YAMLException, "Unable to load yaml file. #{e.message}"
    end

    def get_interaction_objects
      @yaml_data["nodes"].each do |k, opts|
        opts.transform_keys!(&:to_sym)
        @tui_interactions.store(k.to_sym, ChefLicensing::TUIEngine::TUIInteraction.new(opts))
      end
    end

    def build_interaction_path
      @yaml_data["nodes"].each do |k, opts|
        current_interaction = @tui_interactions[k.to_sym]
        opts.transform_keys!(&:to_sym)
        opts[:paths].each do |path|
          current_interaction.paths.store(path.to_sym, @tui_interactions[path.to_sym])
        end
      end
    end

    def run_interaction
      current_interaction = @tui_interactions[:initial_greet]

      state = ChefLicensing::TUIEngine::TUIEngineState.new(@opts)
      until current_interaction.nil?
        state.send(current_interaction.action, current_interaction) if state.respond_to?(current_interaction.action)

        if state.next_interaction_id.nil?
          current_interaction = nil
        else
          current_interaction = current_interaction.paths[state.next_interaction_id.to_sym]
        end
      end

      state.processed_input
    end
  end
end