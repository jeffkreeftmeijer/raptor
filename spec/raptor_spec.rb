require 'mocha'

class Object
  include Mocha::API
end

require File.expand_path('../../lib/raptor', __FILE__)

# descibe Raptor::Should

  # describe #initialize

    # it stores the object
      should = Raptor::Should.new(true)
      should.instance_variable_get(:@object).should == true

  # describe #==

    # it compares the object with the comparison
      should = Raptor::Should.new(false)
      should.stubs(:puts)
      should.==(true).should == false

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
      should.class.should == Raptor::Should
      should.instance_variable_get(:@object).should == object
