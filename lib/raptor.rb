module Raptor

  class << self
    attr_writer :depth

    def contexts
      @contexts ||= []
    end

    def depth
      @depth ||= 0
    end

    def run
      contexts.each { |context| context.run }
    end
  end

  class Should

    def initialize(object)
      @object = object
    end

    def ==(comparison)
      result = @object == comparison
      raise(Error, "Expected #{comparison.inspect}, got #{@object.inspect}") unless result
      result
    end

  end

  class Context

    def contexts
      @contexts ||= []
    end

    def examples
      @examples ||= []
    end

    def initialize(description, &block)
      @description = description
      @block = block
    end

    def run
      Raptor::Formatter.context_started(@description)
      result = instance_eval(&@block)
      Raptor.depth += 1
      examples.each { |example| example.run }
      contexts.each { |context| context.run }
      Raptor.depth -= 1
      result
    end

    def context(description, &block)
      context = Raptor::Context.new(description, &block)
      contexts << context
      context
    end

    alias_method :describe, :context

    def example(description, &block)
      example = Example.new(description, &block)
      examples << example
      example
    end

    alias_method :it, :example

  end

  class Example

    def initialize(description, &block)
      @description = description
      @block = block
    end

    def run
      begin
        result = instance_eval(&@block)
      rescue Object => exception
        Raptor::Formatter.example_failed(@description, exception)
      else
        Raptor::Formatter.example_passed(@description)
      ensure
        return result
      end
    end

  end

  class Formatter

    def self.context_started(description)
      puts "#{'  ' * Raptor.depth}#{description}"
    end

    def self.example_passed(description)
      puts "#{'  ' * Raptor.depth}\e[32m#{description}\e[0m"
    end

    def self.example_failed(description, exception)
      puts "#{'  ' * Raptor.depth}\e[31m#{description}\e[0m"
      puts exception.inspect
    end

  end

  class Error < StandardError
  end

end

class Object

  def should
    Raptor::Should.new(self)
  end

end

module Kernel

  def context(description, &block)
    context = Raptor::Context.new(description, &block)
    Raptor.contexts << context
    context
  end

  alias_method :describe, :context

end
