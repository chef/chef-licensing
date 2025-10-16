module ChefLicensing
  # String refinements to provide pluralization functionality
  # Replaces ActiveSupport::Inflector for our specific use case
  module StringRefinements
    refine String do
      def pluralize(count = 2)
        return self if count == 1

        # Simple pluralization rules
        case self.downcase
        when /s$/, /sh$/, /ch$/, /x$/, /z$/
          "#{self}es"
        when /[^aeiou]y$/
          "#{self[0..-2]}ies"
        when /f$/
          "#{self[0..-2]}ves"
        when /fe$/
          "#{self[0..-3]}ves"
        else
          "#{self}s"
        end
      end
    end
  end
end
