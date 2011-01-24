require File.expand_path('../../lib/raptor', __FILE__)

# descibe Raptor::Should

  # describe #initialize

    # it stores the object
      should = Raptor::Should.new(true)
      puts should.instance_variable_get(:@object) == true

  # describe #==

    # it compares the object with the comparison
      should = Raptor::Should.new(false)
      puts should.==(false) == true

# describe Object

  # describe #should

    # it returns an instance of Raptor::Should
      object = Object.new
      should = object.should
      puts should.class == Raptor::Should
      puts should.instance_variable_get(:@object) == object
