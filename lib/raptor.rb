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

    def initialize(description)
      @description = description
    end

  end

end

class Object

  def should
    Raptor::Should.new(self)
  end

end

module Kernel

  def context(description)
    Raptor::Context.new(description)
  end

end
