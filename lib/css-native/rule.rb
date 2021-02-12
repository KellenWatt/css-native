require "css-native/rule/stylesheet"
class CSSNative
  class Rule
    def initialize(parent, name = "", previous: nil)
      @previous = previous
      @parent = parent
      @selector = name.to_s
      @stylesheet = Stylesheet.new(self)
    end

    # basic selectors
    def with_element(name, &block)
      raise SelectorError.new(element: name, previous: @previous) if previous_selector?
      @previous = :element
      @selector += CSSNative::format_element(name)
      chain(&block)
    end

    def with_class(name, &block)
      @previous = :class
      @selector += CSSNative::format_class(name)
      chain(&block)
    end

    def with_id(name, &block)
      @previous = :id
      @selector += CSSNative::format_id(name)
      chain(&block)
    end

    def with_attribute(name, operation = :none, value = nil, case_sensitive: true, &block)
      @previous = :attribute
      @selector += CSSNative::format_attribute(name, operation, value, case_sensitive: case_sensitive)
      chain(&block)
    end

    def with(name, *args, type: :element, &block)
      case type
      when :element
        if name == :all
          all(&block)
        else
          with_element(name, &block)
        end
      when :class
        with_class(name, &block)
      when :id
        with_id(name, &block)
      when :attribute
        with_attribute(name, *args, &block)
      else
        raise RuleError.new("undefined rule type '#{type}' for css selector")
      end
    end
    alias_method :select, :with

    def all(&block)
      raise SelectorError.new(element: "*", previous: @previous) if previous_selector?
      @previous = :all
      @selector += "*"
      chain(&block)
    end

    # Grouping selectors
    def join(rule = nil)
      raise SelectorError.new(element: ",", previous: @previous) if previous_combinator?
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
      raise SelectorError.new(element: COMBINATORS[m].strip, previous: @previous) if previous_combinator?
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

      args.each? do |arg|
        unless matches_arg_defs?(PSEUDO_CLASSES[m], arg.to_s)
          raise PseudoClassError.new(argument: arg, method: pc)
        end
      end
      
      @previous = :pseudo_class
      @selector += ":#{pc}"
      @selector += "(#{args.join(" ")})" unless args.empty?
      chain(&block)
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
     
      args.each? do |arg|
        unless matches_arg_defs?(PSEUDO_ELEMENTS[m], arg.to_s)
          raise PseudoElementError.new(argument: arg, method: pe)
        end
      end
      
      @previous = :pseudo_element
      @selector += "::#{pe}"
      @selector += "(#{args.join(" ")})" unless args.empty?

      # Not "chain" because a pseudo-element is always the final selector
      @stylesheet.instance_exec(@stylesheet, &block)
      @parent.rules << to_s 
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

    # If a block is given, executes that as a stylesheet. Otherwise, returns self to 
    # facilitate chaining
    def chain(&block)
      if block_given?
        @stylesheet.instance_exec(@stylesheet, &block)
        @parent.rules << to_s 
      else  
        self
      end
    end

    def matches_arg_defs?(defs, arg)
      if defs.nil?
        arg.nil?
      else
        defs.empty? || defs.any? {|d| d === arg}
      end
    end
  end
end
