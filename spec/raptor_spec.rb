require File.expand_path('../spec_helper', __FILE__)

# descibe Raptor::Should

  # describe #initialize

    # it stores the object
      should = Unstable::Raptor::Should.new(true)
      should.instance_variable_get(:@object).should == true

  # describe #==

    # it compares the object with the comparison
      should = Unstable::Raptor::Should.new(false)
      should.stubs(:puts)
      should.==(true).should == false

    # it prints the result
      mocha_setup
      should = Unstable::Raptor::Should.new(true)
      should.expects(:puts).with(false)
      should.==(false)
      mocha_verify
      mocha_teardown

# descibe Raptor::Context

  # descibe #initialize

    # it stores the description
      context = Unstable::Raptor::Context.new('foo')
      context.instance_variable_get(:@description).should == 'foo'


# describe Object

  # describe #should

    # it returns an instance of Raptor::Should
      object = Unstable::Object.new
      should = object.should
      should.class.should == Raptor::Should
      should.instance_variable_get(:@object).should == object

# describe Kernel

  #describe #context

    # it returns an instance of Raptor::Context
      Unstable::Kernel.context('foo').class.should == Raptor::Context
