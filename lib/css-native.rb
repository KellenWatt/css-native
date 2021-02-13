require "css-native/errors"
require "css-native/rule"

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

  def element(name, &block)
    Rule.new(self).with_element(name, &block)
  end

  alias_method :klass, :class
  def class(name = nil, &block)
    if name.nil?
      klass
    else
      Rule.new(self).with_class(name, &block)
    end
  end

  def id(name, &block)
      Rule.new(self).with_id(name, &block)
  end
  
  def attribute(name, operation = :none, value = nil, case_sensitive: true, &block)
      Rule.new(self).with_attribute(name, operation, value, case_sensitive: case_sensitive, &block)
  end

  def select(name, *args, type: :element, &block)
    case type
    when :element
      Rule.new(self).with(name, &block)
    when :class
      self.class(name, &block)
    when :id
      id(name, &block)
    when :attribute
      attribute(name, *args, &block)
    else
      raise RuleError.new(rule: type)
    end
  end

  def to_s
    @rules.join("\n")
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
