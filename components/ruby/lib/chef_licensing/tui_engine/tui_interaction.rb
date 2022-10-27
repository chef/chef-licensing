module ChefLicensing
  class TUIEngine
    class TUIInteraction
      attr_accessor :id, :messages, :action, :paths, :prompt_type, :response_path_map, :prompt_attributes, :description
      def initialize(opts = {})
        @id = opts[:id]
        @messages = opts[:messages]
        @action = opts[:action]
        @prompt_type = opts[:prompt_type] || "say"
        @prompt_attributes = opts[:prompt_attributes] || {}
        @response_path_map = opts[:response_path_map]
        @paths = {}
        @description = opts[:description] || ""
      end
    end
  end
end
