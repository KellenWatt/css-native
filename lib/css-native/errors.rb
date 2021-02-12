class CSSNative
  class CSSError < StandardError
    def initialize(msg = "Invalid CSS")
      super(msg)
    end
  end
  
  class RuleError < CSSError
    def initialize(msg = "Invalid rule type", rule: nil)
      if rule.nil?
        super(msg)
      else
        super("Invalid rule type '#{rule}'")
      end
    end
  end
  
  class AttributeComparisonError < CSSError
    def initialize(msg = "Invalid attrubute comparison", comparison: nil)
      if comparison.nil?
        super(msg)
      else
        super(msg + " '#{comparison}'")
      end
    end
  end
  
  class SelectorError < RuleError
    def initialize(msg = "Selector not valid", element: nil, previous: nil)
      if element.nil? && previous.nil?
        super(msg)
      elsif previous.nil?
        super("Selector '#{element}' not valid")
      else
        super("Selector '#{element}' not valid after '#{previous}' selector part")
      end
    end
  end
  
  class PseudoClassError < RuleError
    def initialize(msg = "invalid pseudo-class", argument: nil, method: nil)
      if argument.nil? && method.nil?
        super(msg)
      elsif argument.nil?
        super("invalid pseudo-class '#{method}'")
      else
        super("argument '#{argument}' invalid for pseudo-class '#{method}'")
      end
    end
  end
  
  class PseudoElementError < RuleError
    def initialize(msg = "invalid pseudo-element", argument: nil, method: nil)
      if argument.nil? && method.nil?
        super(msg)
      elsif argument.nil?
        super("invalid pseudo-element '#{method}'")
      else
        super("argument '#{argument}' invalid for pseudo-element '#{method}'")
      end
    end
  end
end
