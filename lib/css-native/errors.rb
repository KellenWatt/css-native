class CSSNative
  class CSSError < StandardError
  end
  
  class RuleError < CSSError
  end
  
  class GrammarError < RuleError
    def initialize(element = nil)
      super("Rule selector#{element.nil? ? "" : " #{element}"} not valid in current position")
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

  class AttributeError < CSSError
  end
end
