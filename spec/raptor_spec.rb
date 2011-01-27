require File.expand_path('../spec_helper', __FILE__)

describe Raptor do

  describe ".contexts" do

    it "is an array to store contexts" do
      Unstable::Raptor.contexts.class.should == Array
    end

    it "is writable" do
      Unstable::Raptor.contexts << :context
      Unstable::Raptor.contexts.should == [:context]
    end

  end

end

describe Raptor::Should do

  describe "#initialize" do

    it "stores the object" do
      should = Unstable::Raptor::Should.new(true)
      should.instance_variable_get(:@object).should == true
    end

  end

  describe "#==" do

    it "compares the object with the comparison" do
      should = Unstable::Raptor::Should.new(false)
      should.==(false).should == true
    end

    it "raises a Raptor::Error when the comparison fails" do
      mocha_setup
      should = Unstable::Raptor::Should.new(true)
      should.expects(:raise).with(Raptor::Error, 'Expected false, got true')
      should.==(false)
      mocha_verify
      mocha_teardown
    end

  end

end

describe Raptor::Context do

  describe "#initialize" do

    it "stores the description" do
      context = Unstable::Raptor::Context.new('foo')
      context.instance_variable_get(:@description).should == 'foo'
    end

    it "stores the block" do
      context = Unstable::Raptor::Context.new('foo') { 'baz' }
      context.instance_variable_get(:@block).call.should == 'baz'
    end

  end

  describe "#run" do

    it "runs the block" do
      context = Unstable::Raptor::Context.new('foo') { 'baz' }
      context.run.should == 'baz'
    end

    it "runs nested contexts" do
      called = false
      parent_context = Unstable::Raptor::Context.new('foo') {}
      parent_context.context('bar') { called = true }
      parent_context.run
      called.should == true
    end

    it "runs nested examples" do
      called = false
      context = Unstable::Raptor::Context.new('foo') {}
      context.example('bar') { called = true }
      context.run
      called.should == true
    end

    it "runs in context" do
      context = Unstable::Raptor::Context.new('foo') { self }
      context.run.should == context
    end

  end

  describe "#contexts" do

    it "is an array to store contexts" do
      parent_context = Unstable::Raptor::Context.new('foo')
      parent_context.contexts.class.should == Array
    end

    it "is writable" do
      parent_context = Unstable::Raptor::Context.new('foo')
      parent_context.contexts << :context
      parent_context.contexts.should == [:context]
    end

  end

  describe "#context" do

    it "returns an instance of Raptor::Context" do
      parent_context = Unstable::Raptor::Context.new('foo')
      context = parent_context.context('bar') { 'baz' }
      context.class.should == Raptor::Context
      context.instance_variable_get(:@description).should == 'bar'
      context.instance_variable_get(:@block).call.should == 'baz'
    end

    it "adds a context to parent_context#contexts" do
      parent_context = Unstable::Raptor::Context.new('foo')
      context = parent_context.context('foo')
      parent_context.contexts.pop.should == context
    end

  end

  describe "#describe" do

    it "is an alias for #context" do
      parent_context = Unstable::Raptor::Context.new('foo')
      parent_context.describe('foo').class.should == Raptor::Context
    end

  end

  describe "#examples" do

    it "is an array to store contexts" do
      context = Unstable::Raptor::Context.new('foo')
      context.examples.class.should == Array
    end

    it "is writable" do
      context = Unstable::Raptor::Context.new('foo')
      context.examples << :context
      context.examples.should == [:context]
    end

  end

  describe "#example" do

    it "returns an instance of Raptor::Example" do
      context = Unstable::Raptor::Context.new('foo')
      example = context.example('foo') { 'bar' }
      example.class.should == Raptor::Example
      example.instance_variable_get(:@description).should == 'foo'
      example.instance_variable_get(:@block).call.should == 'bar'
    end

    it "adds an example to context.examples" do
      context = Unstable::Raptor::Context.new('foo')
      example = context.example('foo')
      context.examples.pop.should == example
    end

  end

  describe "#it" do

    it "is an alias for #example" do
      context = Unstable::Raptor::Context.new('foo')
      context.it('foo').class.should == Raptor::Example
    end

  end

end

describe Raptor::Example do

  describe "#initialize" do

    it "stores the description" do
      example = Unstable::Raptor::Example.new('foo')
      example.instance_variable_get(:@description).should == 'foo'
    end

    it "stores the block" do
      example = Unstable::Raptor::Example.new('foo') { 'baz' }
      example.instance_variable_get(:@block).call.should == 'baz'
    end

  end

  describe "#run" do

    it "runs the block" do
      example = Unstable::Raptor::Example.new('foo') { 'baz' }
      example.run.should == 'baz'
    end

     it "prints a red F and the error message when an error is raised" do
       mocha_setup
       example = Unstable::Raptor::Example.new('foo') { raise 'omgno!' }
       example.expects(:puts).with("\e[31mF\e[0m")
       example.expects(:puts).with('#<RuntimeError: omgno!>')
       example.run
       mocha_verify
       mocha_teardown
     end

     it "prints a green dot when no error is raised" do
       mocha_setup
       example = Unstable::Raptor::Example.new('foo') {  }
       example.expects(:puts).with("\e[32m.\e[0m")
       example.run
       mocha_verify
       mocha_teardown
     end

  end

end

describe Object do

  describe "#should" do

    it "returns an instance of Raptor::Should" do
      object = Unstable::Object.new
      should = object.should
      should.class.should == Raptor::Should
      should.instance_variable_get(:@object).should == object
    end

  end

end

describe Kernel do

  describe "#context" do

    it "returns an instance of Raptor::Context" do
      context = Unstable::Kernel.context('foo') { 'bar' }
      context.class.should == Raptor::Context
      context.instance_variable_get(:@description).should == 'foo'
      context.instance_variable_get(:@block).call.should == 'bar'
      Raptor.contexts.pop # clean up the created context
    end

    it "adds a context to Raptor#contexts" do
      context = Unstable::Kernel.context('foo')
      Raptor.contexts.pop.should == context
    end

  end

  describe "#describe" do

    it "is an alias for #context" do
      Unstable::Kernel.describe('foo').class.should == Raptor::Context
      Raptor.contexts.pop # clean up the created context
    end

  end

end
