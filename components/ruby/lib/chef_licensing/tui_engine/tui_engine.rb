require_relative "tui_exceptions"
require_relative "tui_interaction"
require_relative "tui_engine_state"

module ChefLicensing
  class TUIEngine

    attr_accessor :yaml_data, :tui_interactions, :opts

    def initialize(opts = {})
      @opts = opts
      @tui_interactions = {}
      initialization_of_engine(opts[:yaml_file])
    end

    def run_interaction
      current_interaction = @tui_interactions[:start]
      state = ChefLicensing::TUIEngine::TUIEngineState.new(@opts)

      until current_interaction.nil?
        state.default_action(current_interaction)

        # TBD: Error handling in situation of invalid next_interaction_id

        if state.next_interaction_id.nil?
          current_interaction = nil
        else
          current_interaction = current_interaction.paths[state.next_interaction_id.to_sym]
        end
      end

      # TBD: If the last interaction is not the exit interaction: Something went wrong in the flow.

      state.processed_input
    end

    private

    def initialization_of_engine(yaml_file)
      yaml_file ||= File.join(File.dirname(__FILE__), "default_flow.yaml")
      @yaml_data = inflate_yaml_data(yaml_file)
      verify_yaml_data
      store_interaction_objects
      build_interaction_path
    end

    def inflate_yaml_data(yaml_file)
      require "yaml" unless defined?(YAML)
      YAML.load_file(yaml_file)
    rescue => e
      raise ChefLicensing::TUIEngine::YAMLException, "Unable to load yaml file. #{e.message}"
    end

    def store_interaction_objects
      @yaml_data["interactions"].each do |k, opts|
        opts.transform_keys!(&:to_sym)
        opts.store(:id, k.to_sym)
        @tui_interactions.store(k.to_sym, ChefLicensing::TUIEngine::TUIInteraction.new(opts))
      end
    end

    def build_interaction_path
      @yaml_data["interactions"].each do |k, opts|
        current_interaction = @tui_interactions[k.to_sym]
        opts.transform_keys!(&:to_sym)
        paths = opts[:paths] || []
        paths.each do |path|
          current_interaction.paths.store(path.to_sym, @tui_interactions[path.to_sym])
        end
      end
    end

    def verify_yaml_data
      raise ChefLicensing::TUIEngine::YAMLException, "No interactions found in yaml file." unless @yaml_data

      raise ChefLicensing::TUIEngine::YAMLException, "`interactions` key not found in yaml file." unless @yaml_data["interactions"]

      @yaml_data["interactions"].each do |i_id, opts|
        if opts[:action] && opts[:messages]
          warn "Both `action` and `messages` keys found in yaml file for interaction #{i_id}."
          warn "`response_path_map` keys would be considered response from messages and not action."
        end

        opts.transform_keys!(&:to_sym)

        opts.each do |k, val|
          unless %i{action messages paths prompt_type response_path_map description}.include?(k)
            warn "Invalid key `#{k}` found in yaml file for interaction #{i_id}."
            warn "Valid keys are `action`, `messages`, `paths`, `prompt_type`, `response_path_map` and `description`."
            warn "#{k} will be ignored.\nYour yaml file may not work as expected."
          end

          # check prompt_type value is valid
          if k == :prompt_type
            unless %w{yes say ask ok warn error select enum_select}.include?(val)
              raise ChefLicensing::TUIEngine::YAMLException, "Invalid value `#{val}` for `prompt_type` key in yaml file for interaction #{i_id}."
            end
          end
        end
      end
    end
  end
end
