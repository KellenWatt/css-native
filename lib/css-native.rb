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

  def element(name)
    Rule.new(self).with_element(name)
  end

  alias_method :klass, :class
  def class(name = nil)
    if name.nil?
      klass
    else
      Rule.new(self).with_class(name)
    end
  end

  def id(name)
      Rule.new(self).with_id(name)
  end
  
  def attribute(name, operation = :none, value = nil, case_sensitive: true)
      Rule.new(self).with_attribute(name, operation, value, case_sensitive: case_sensitive)
  end

  def select(name, *args, type: :element)
    case type
    when :element
      Rule.new(self).with(name)
    when :class
      self.class(name)
    when :id
      id(name)
    when :attribute
      attribute(name, *args)
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
