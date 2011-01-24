require 'mocha'

class Object
  include Mocha::API
end

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

    # it prints the result
      mocha_setup
      should = Raptor::Should.new(true)
      should.expects(:puts).with(false)
      should.==(false)
      mocha_verify
      mocha_teardown

# describe Object

  # describe #should

    # it returns an instance of Raptor::Should
      object = Object.new
      should = object.should
      puts should.class == Raptor::Should
      puts should.instance_variable_get(:@object) == object
