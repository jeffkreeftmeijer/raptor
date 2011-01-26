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
      puts result
      result
    end

  end

  class Context

    def contexts
      @contexts ||= []
    end

    def initialize(description, &block)
      @description = description
      @block = block
    end

    def run
      result = instance_eval(&@block)
      contexts.each { |context| context.run }
      result
    end

    def context(description, &block)
      context = Raptor::Context.new(description, &block)
      contexts << context
      context
    end

    alias_method :describe, :context

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
