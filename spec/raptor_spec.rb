require File.expand_path('../spec_helper', __FILE__)

# descibe Raptor

  #descibe .contexts

    #it is an array to store contexts
      Unstable::Raptor.contexts.class.should == Array

    #it is writable
      Unstable::Raptor.contexts << :context
      Unstable::Raptor.contexts.should == [:context]

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

    # it stores the block
      context = Unstable::Raptor::Context.new('foo') { 'baz' }
      context.instance_variable_get(:@block).call.should == 'baz'

  # describe #run

    # it runs the block
      context = Unstable::Raptor::Context.new('foo') { 'baz' }
      context.run.should == 'baz'

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

    # it adds a context to Raptor#contexts
      context = Unstable::Kernel.context('foo')
      Raptor.contexts.last.should == context
