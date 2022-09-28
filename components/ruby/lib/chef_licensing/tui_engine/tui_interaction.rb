module ChefLicensing
  class TUIEngine
    class TUIInteraction
      attr_accessor :messages, :action, :paths
      def initialize(opts = {})
        @messages = opts[:messages]
        @action = opts[:action]
        @paths = []
      end
    end
  end
end
