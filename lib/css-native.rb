class CSSNative
  private_class_method :new
  def self.stylesheet(&block)
    sheet = new
    sheet.instance_eval(&block)
    sheet
  end

  attr_reader :rules
  def initialize
    @rules = []
  end

  alias_method :klass, :class
  def class(name = nil)
    if name.nil?
      klass
    else
      ".#{name}"
    end
  end

  def id(name)
    "##{name}"
  end

  def attribute(name, operation = :none, value = nil, case_sensitive: true)
    op = case operation.to_sym
         when :none        then ""
         when :equals      then "="
         when :include     then "~="
         when :matches     then "|="
         when :starts_with then "^="
         when :ends_with   then "$="
         when :contains    then "*="
         else
           raise AttributeError.new("undefined comparison '#{operation}' for css attribute selector")
         end
    "[#{name}#{op}#{value.nil? ? "" : "\"#{value}\""}#{case_sensitive ? "" : " i"}]"
  end

  def select(name, *args, type: :element)
    case type
    when :element
      Rule.new(self).with(name)
    when :class
      Rule.new(self).with_class(name)
    when :id
      Rule.new(self).with_id(name)
    when :attribute
      Rule.new(self).with_attribute(name, *args)
    else
      raise RuleError.new("undefined rule type '#{type}' for css selector")
    end
  end

  def to_s
    @rules.join("\n")
  end

  private

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

  class Rule
    def initialize(parent, name = "", previous: nil)
      @previous = previous
      @parent = parent
      @selector = name.to_s
      @body = {}
      @stylesheet = Stylesheet.new(self)
    end

    # basic selectors
    def with_class(name, &block)
      s = @parent.class(name)
      @previous = :class
      @selector += s
      if block_given?
        @stylesheet.instance_exec(@stylesheet, &block)
        @parent.rules << to_s
      else
        self
      end
    end

    def with_id(name, &block)
      s = @parent.id(name)
      @previous = :id
      @selector += s
      if block_given?
        @stylesheet.instance_exec(@stylesheet, &block)
        @parent.rules << to_s
      else
        self
      end
    end

    def with_attribute(name, operation = :none, value = nil, case_sensitive: true, &block)
      s = @parent.attribute(name, operation, value, case_sensitive: case_sensitive)
      @previous = :attr
      @selector += s
      if block_given?
        @stylesheet.instance_exec(@stylesheet, &block)
        @parent.rules << to_s
      else
        self
      end
    end

    def with(name, *args, type: :element, &block)
      case type
      when :element
        name = (name == :all ? "*" : name.to_s)
        raise GrammarError.new(name) if previous_selector?
        @previous = (name == :all ? :all : :element)
        @selector += name
        if block_given?
          @stylesheet.instance_exec(@stylesheet, &block)
          @parent.rules << to_s
        else
          self
        end
      when :class
        with_class(name, &block)
      when :id
        with_id(name, &block)
      when :attribute
        with_attribute(name, *args, &block)
      else
        raise CSSNative::RuleError.new("undefined rule type '#{type}' for css selector")
      end
    end
    alias_method :select, :with

    def all(&block)
      raise GrammarError.new("*") if previous_selector?
      @previous = :all
      @selector += "*"
      if block_given?
        @stylesheet.instance_exec(@stylesheet, &block)
        @parent.rules << to_s
      else
        self
      end
    end

    # Grouping selectors
    def join(rule = nil)
      raise GrammarError.new(",") if previous_combinator?
      @previous = :join
      @selector += ","
      if rule.kind_of? Rule
        @selector += rule.instance_variable_get(:@selector)
      else
        @selector += rule.to_s
      end
      self
    end

    # Combinators
    COMBINATORS = {
      descendant: " ",
      child: " > ",
      sibling: " + ",
      adjacent: " + ",
      column: " || "
    }

    def combinator(c)
      m = c.to_sym
      raise GrammarError.new(COMBINATORS[]) if previous_combinator?
      @previous = :combinator
      @selector += COMBINATORS[m]
      self
    end

    # pseudo-classes
    # name of value is pseudo-class, array values are acceptad options
    #   Equality is compared by <option> === <value>, allowing 
    #   classes to test for instances or regex matching
    # If array is empty, there's no limitations (in the code, foraml CSS may differ)
    # If array is nil, it takes no options
    PSEUDO_CLASSES = {
      # Linguistic
      dir: ["ltr", "rtl"],
      lang: [],
      # Location
      "any_link": nil,
      link: nil,
      visited: nil,
      "local_link": nil,
      target: nil,
      "target_within": nil,
      scope: nil,
      # User action
      hover: nil,
      active: nil,
      focus: nil,
      "focus_visible": nil,
      "focus_within": nil,
      # Time_dimensional _ ill_defined
      current: nil,
      past: nil,
      future: nil,
      # Resource state
      playing: nil,
      paused: nil,
      # Input
      enabled: nil,
      disabled: nil,
      "read_only": nil,
      "read_write": nil,
      "placeholder_shown": nil,
      default: nil,
      checked: nil,
      indeterminate: nil,
      blank: nil,
      valid: nil,
      invalid: nil,
      "in_range": nil,
      "out_of_range": nil,
      required: nil,
      optional: nil,
      "user_invalid": nil,
      root: nil,
      empty: nil,
      "nth_child": ["odd", "even", /^\d+(n(\s*\+\s*\d+)?)?$/],
      "nth_last_child": ["odd", "even", /^\d+(n(\s*\+\s*\d+)?)?$/],
      "first_child": nil,
      "last_child": nil,
      "only_child": nil,
      "nth_of_type": ["odd", "even", /^\d+(n(\s*\+\s*\d+)?)?$/],
      "nth_last_of_type": ["odd", "even", /^\d+(n(\s*\+\s*\d+)?)?$/],
      "first_of_type": nil,
      "last_of_type": nil,
      "only_of_type": nil,
    }
   
    def pseudo_class(name, *args, &block)
      pc = name.to_s.gsub("_", "-")
      m = name.to_s.gsub("-", "_").to_sym
      raise PseudoClassError.new(method: pc) unless PSEUDO_CLASSES.key?(m)
      arg_defs = PSEUDO_CLASSES[m]
      @previous = :pseudo_class
      args.all? do |arg|
        raise PseudoClassError.new(argument: arg, method: pc) unless matches_arg_defs?(arg_defs, arg.to_s)
      end
      @selector += ":" + pc
      @selector += "(#{args.join(" ")})" unless args.empty?
      if block_given?
        @stylesheet.instance_exec(@stylesheet, &block)
        @parent.rules << to_s
      else
        self
      end
    end

    # pseudo-elements
    # definition semantics same as pseudo-classes
    PSEUDO_ELEMENTS = {
      after: nil,
      before: nil,
      backdrop: nil,
      cue: nil,
      "cue_region": nil,
      "first_letter": nil,
      "first_line": nil,
      "file_selector_button": nil,
      "grammar_error": nil,
      marker: nil,
      part: [/[-a-zA-Z]+( [-a-zA-Z]+)?/],
      placeholder: nil,
      selection: nil,
      slotted: [],
      "spelling_error": nil,
      "target_text": nil,
    }

    def pseudo_element(name, *args, &block)
      pe = name.to_s.gsub("_", "-")
      m = name.to_s.gsub("-", "_").to_sym
      raise PseudoElementError.new(method: pe) unless PSEUDO_ELEMENTS.key?(m)
      arg_defs = PSEUDO_ELEMENTS[m]
      @previous = :pseudo_element
      args.all? do |arg|
        raise PseudoElementError.new(argument: arg, method: ps) unless matches_arg_defs?(arg_defs, arg.to_s) 
      end
      @selector += "::" + pe
      @selector += "(#{args.join(" ")})" unless args.empty?
      if block_given?
        @stylesheet.instance_exec(@stylesheet, &block)
        @parent.rules << to_s
      else
        self
      end 
    end

    def method_missing(m, *args, &block)
      if COMBINATORS.key?(m)
        combinator(m)
      elsif PSEUDO_CLASSES.key?(m)
        pseudo_class(m, *args, &block)
      elsif PSEUDO_ELEMENTS.key?(m)
        pseudo_element(m, *args, &block)
      else
        super(m, *args, &block)
      end
    end

    def respond_to_missing?(m, include_all = false)
      COMBINATORS.key?(m) ||
      PSEUDO_CLASSES.key?(m) ||
      PSEUDO_ELEMENTS.key?(m) ||
      super(m, include_all)
    end

    def to_s
      "#{@selector} #{@stylesheet}"
    end

    private

    def previous?(*args)
      args.include?(@previous)
    end

    def previous_combinator?
      previous?(:join, :combinator)
    end

    def previous_selector?
      previous?(:element, :class, :id, :attribute, :all, :pseudo_class, :pseudo_element)
    end

    def matches_arg_defs?(defs, arg)
      if defs.nil?
        arg.nil?
      elsif defs.empty?
        true
      else
        defs.any? {|d| d === arg}
      end
    end

    class Stylesheet
      def initialize(controller)
        @properties = {}
        @controller = controller
      end

      def subrule
        parent = @controller.instance_variable_get(:@parent)        
        selector = @controller.instance_variable_get(:@selector)
        previous = @controller.instance_variable_get(:@previous)
        puts previous
        
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

class Numeric
  [:em, :ex, :ch, :rem, :lh, :vw, :vh, :vmin, 
   :vmax, :px, :pt, :pc, :in, :Q, :mm, :cm].each do |m|
    define_method(m) {"#{self}#{m}"}
  end
  def pct
    "#{self}%"
  end
  alias_method :percent, :pct
end
