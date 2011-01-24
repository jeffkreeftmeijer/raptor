module Raptor

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

end

class Object

  def should
    Raptor::Should.new(self)
  end

end
