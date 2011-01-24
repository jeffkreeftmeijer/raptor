module Raptor

  class Should

    def initialize(object)
      @object = object
    end

    def ==(comparison)
      @object == comparison
    end

  end

end

class Object

  def should
    Raptor::Should.new(self)
  end

end
