require File.expand_path('../spec_helper', __FILE__)

describe Raptor do

  describe ".contexts" do

    #it is an array to store contexts
      Unstable::Raptor.contexts.class.should == Array

    #it is writable
      Unstable::Raptor.contexts << :context
      Unstable::Raptor.contexts.should == [:context]

  end

end

describe Raptor::Should do

  describe "#initialize" do

    # it stores the object
      should = Unstable::Raptor::Should.new(true)
      should.instance_variable_get(:@object).should == true

  end

  describe "#==" do

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

  end

end

describe Raptor::Context do

  describe "#initialize" do

    # it stores the description
      context = Unstable::Raptor::Context.new('foo')
      context.instance_variable_get(:@description).should == 'foo'

    # it stores the block
      context = Unstable::Raptor::Context.new('foo') { 'baz' }
      context.instance_variable_get(:@block).call.should == 'baz'

  end

  describe "#run" do

    # it runs the block
      context = Unstable::Raptor::Context.new('foo') { 'baz' }
      context.run.should == 'baz'

    # it runs nested contexts
      called = false
      parent_context = Unstable::Raptor::Context.new('foo') {}
      parent_context.context('bar') { called = true }
      parent_context.run
      called.should == true

  end

  describe "#contexts" do

    #it is an array to store contexts
      parent_context = Unstable::Raptor::Context.new('foo')
      parent_context.contexts.class.should == Array

    #it is writable
      parent_context = Unstable::Raptor::Context.new('foo')
      parent_context.contexts << :context
      parent_context.contexts.should == [:context]

  end

  describe "#context" do

    # it returns an instance of Raptor::Context
      parent_context = Unstable::Raptor::Context.new('foo')
      context = parent_context.context('bar') { 'baz' }
      context.class.should == Raptor::Context
      context.instance_variable_get(:@description).should == 'bar'
      context.instance_variable_get(:@block).call.should == 'baz'

    # it adds a context to parent_context#contexts
      parent_context = Unstable::Raptor::Context.new('foo')
      context = parent_context.context('foo')
      parent_context.contexts.pop.should == context

  end

  describe "#describe" do

    # it is an alias for #context
      parent_context = Unstable::Raptor::Context.new('foo')
      parent_context.describe('foo').class.should == Raptor::Context

  end

end

describe Object do

  describe "#should" do

    # it returns an instance of Raptor::Should
      object = Unstable::Object.new
      should = object.should
      should.class.should == Raptor::Should
      should.instance_variable_get(:@object).should == object

  end

end

describe Kernel do

  describe "#context" do

    # it returns an instance of Raptor::Context
      context = Unstable::Kernel.context('foo') { 'bar' }
      context.class.should == Raptor::Context
      context.instance_variable_get(:@description).should == 'foo'
      context.instance_variable_get(:@block).call.should == 'bar'
      Raptor.contexts.pop # clean up the created context

    # it adds a context to Raptor#contexts
      context = Unstable::Kernel.context('foo')
      Raptor.contexts.pop.should == context

  end

  describe "#describe" do

    # it is an alias for #context
      Unstable::Kernel.describe('foo').class.should == Raptor::Context
      Raptor.contexts.pop # clean up the created context

  end

end
