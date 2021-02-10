class CSSNative
  class Rule
    private
    class Stylesheet
      def initialize(controller)
        @properties = {}
        @controller = controller
      end

      def subrule
        parent = @controller.instance_variable_get(:@parent)        
        selector = @controller.instance_variable_get(:@selector)
        previous = @controller.instance_variable_get(:@previous)
        
        Rule.new(parent, selector, previous: previous)
      end

      def to_s
        "{\n" + 
        @properties.map do |k, v|
          "  #{k}: #{v};"
        end.join("\n") +
        "\n}"
      end

      def method_missing(m, *args, &block)
        if m.to_s.end_with? "="
          props = args[0]
          props = props.join(" ") if props.kind_of?(Array)
          @properties[m.to_s.gsub("_", "-")[...-1]] = props.to_s
        else
          super(m, *args, &block)
        end
      end
    end
  end
end
