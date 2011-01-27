module Raptor

  def self.contexts
    @contexts ||= []
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
      result = instance_eval(&@block)
      examples.each { |example| example.run }
      contexts.each { |context| context.run }
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
        result = @block.call
      rescue Object => e
        puts "\e[31mF\e[0m"
        puts e.inspect
      else
        puts "\e[32m.\e[0m"
      ensure
        return result
      end
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
