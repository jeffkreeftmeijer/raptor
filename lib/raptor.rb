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

    def initialize(description, &block)
      @description = description
      @block = block
    end

    def run
      @block.call
    end

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
