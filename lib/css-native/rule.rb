require "css-native/rule/stylesheet"
require "css-native/rule/constants"
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
      selector_error(name) if previous_selector?
      append_selector(format_element(name), :element)
      chain(&block)
    end

    def with_class(name, &block)
      append_selector(format_class(name), :class)
      chain(&block)
    end

    def with_id(name, &block)
      append_selector(format_id(name), :id)
      chain(&block)
    end

    def with_attribute(name, op = :none, value = nil, case_sensitive: true, &block)
      append_selector(format_attribute(name, op, value, case_sensitive: case_sensitive), :attribute)
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
      selector_error("*") if previous_selector?
      append_selector("*", :all)
      chain(&block)
    end

    # Grouping selectors
    def join(rule = nil, &block)
      raise JoinError unless rule.kind_of?(Rule) || rule.nil?
      selector_error(",") if previous_combinator?

      if rule.kind_of? Rule
        selector = rule.instance_variable_get(:@selector)
        previous = rule.instance_variable_get(:@previous)

        append_selector("," + selector, previous)
        previous_combinator? ? self : chain(&block)
      else
        append_selector(",", :join)
        self
      end
    end

    # Combinators
    def combinator(c)
      m = c.to_sym
      selector_error(COMBINATORS[m].strip) if previous_combinator?
      append_selector(COMBINATORS[m], :combinator)
      self
    end

    def pseudo_class(name, *args, &block)
      pc = name.to_s.gsub("_", "-")
      m = name.to_s.gsub("-", "_").to_sym
      raise PseudoClassError.new(method: pc) unless PSEUDO_CLASSES.key?(m)

      unless args.all? {|arg| valid_arg?(PSEUDO_CLASSES[m], arg.to_s)}
        raise PseudoClassError.new(argument: arg, method: pc) 
      end
      
      selector = ":#{pc}" + (args.empty? ? "" : "(#{args.join(" ")})")
      append_selector(selector, :pseudo_class)
      chain(&block)
    end

    def pseudo_element(name, *args, &block)
      pe = name.to_s.gsub("_", "-")
      m = name.to_s.gsub("-", "_").to_sym
      raise PseudoElementError.new(method: pe) unless PSEUDO_ELEMENTS.key?(m)
     
      unless args.all? {|arg| valid_arg?(PSEUDO_ELEMENTS[m], arg.to_s)}
        raise PseudoElementError.new(argument: arg, method: pe)
      end

      selector = "::#{pe}" + (args.empty? ? "" : "(#{args.join(" ")})")
      append_selector(selector, :pseudo_element)
      chain(&block)
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

    def append_selector(item, symbol)
      @selector += item
      @previous = symbol
    end

    def selector_error(name)
      raise SelectorError.new(element: name, previous: @previous)
    end

    def valid_arg?(defs, arg)
      if defs.nil?
        arg.nil?
      else
        defs.empty? || defs.any? {|d| d === arg}
      end
    end
    
    def format_element(name)
      name.to_s
    end

    def format_class(name)
      ".#{name}"
    end

    def format_id(name)
      "##{name}"
    end

    def format_attribute(name, operation = :none, value = nil, case_sensitive: true)
      # Other case not possible because of positional arguments
      raise AttributeError if operation != :none && value.nil?

      op = case operation.to_sym
           when :none        then ""
           when :equals      then "="
           when :include     then "~="
           when :matches     then "|="
           when :starts_with then "^="
           when :ends_with   then "$="
           when :contains    then "*="
           else
             raise AttributeComparisonError.new(operation: operation)
           end
      "[#{name}#{op}#{value.nil? ? "" : "\"#{value}\""}#{case_sensitive ? "" : " i"}]"
    end
  end
end
