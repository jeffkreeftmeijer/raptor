require File.expand_path('../../lib/raptor', __FILE__)

# descibe Raptor::Should

  # describe #initialize

    # it stores the object    
      should = Raptor::Should.new(true)
      puts should.instance_variable_get(:@object) == true