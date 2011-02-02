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

  describe ".depth" do

    it "returns the current depth" do
      Unstable::Raptor.depth.should == 0
      Unstable::Raptor.instance_variable_set(:@depth, 1)
      Unstable::Raptor.depth.should == 1
    end

  end

  describe ".formatter" do

    it "returns Raptor::Formatters::Documentation by default" do
      Unstable::Raptor.formatter.to_s.should == 'Raptor::Formatters::Documentation'
    end

  end

  describe ".example" do

    it "returns Raptor::Example by default" do
      Unstable::Raptor.example.to_s.should == 'Raptor::Example'
    end

  end

  describe '.counter' do

    it "returns the current value" do
      Unstable::Raptor.counter['foo'] = 'bar'
      Unstable::Raptor.counter['foo'].should == 'bar'
    end

    it "returns 0 by default" do
      Unstable::Raptor.counter['bar'].should == 0
    end

  end

  describe ".run" do

    it "runs the examples" do
      with_mocha do
        Unstable::Raptor.instance_variable_set(
          :@contexts,
          [Unstable::Raptor::Context.new('foo')] * 3
        )
        Unstable::Raptor.contexts.each { |context| context.expects(:run) }
        Unstable::Raptor.run
      end
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
      with_mocha do
        should = Unstable::Raptor::Should.new(true)
        should.expects(:raise).with(Raptor::Error, 'Expected false, got true')
        should.==(false)
      end
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
      with_mocha do
        context = Unstable::Raptor::Context.new('foo') { 'baz' }
        Raptor.formatter.stubs(:context_started)
        context.run.should == 'baz'
      end
    end

    it "runs nested contexts" do
      with_mocha do
        called = false
        parent_context = Unstable::Raptor::Context.new('foo') {}
        context = parent_context.context('bar') { called = true }
        Raptor.formatter.stubs(:context_started)
        parent_context.run
        called.should == true
      end
    end

    it "runs nested examples" do
      with_mocha do
        called = false
        context = Unstable::Raptor::Context.new('foo') {}
        example = context.example('bar') { called = true }
        Raptor.formatter.stubs(:context_started)
        Raptor.formatter.stubs(:example_passed)
        context.run
        called.should == true
      end
    end

    it "runs in context" do
      context = Unstable::Raptor::Context.new('foo') { self }
      Raptor.formatter.stubs(:context_started)
      context.run.should == context
    end

    it "increases Raptor.depth while running nested examples" do
      with_mocha do
        original_depth, depth = Raptor.depth, 0

        context = Unstable::Raptor::Context.new('foo') {}
        example = context.example('bar') { depth = Raptor.depth }

        Raptor.formatter.stubs(:context_started)
        Raptor.formatter.stubs(:example_passed)
        context.run

        depth.should == original_depth + 1
        Raptor.depth.should == original_depth
      end
    end

    it "increases Raptor.depth while running nested contexts" do
      with_mocha do
        original_depth, depth = Raptor.depth, 0

        parent_context = Unstable::Raptor::Context.new('foo') {}
        context = parent_context.context('bar') { depth = Raptor.depth }

        Raptor.formatter.stubs(:context_started)
        Raptor.formatter.stubs(:example_passed) 
        parent_context.run

        depth.should == original_depth + 1
        Raptor.depth.should == original_depth
      end
    end

  end

  it "calls Raptor.formatter#context_started" do
    with_mocha do
      Raptor.formatter.expects(:context_started).with('foo')
      Unstable::Raptor::Context.new('foo') {}.run
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
      Raptor.formatter.stubs(:example_passed)
      example.run.should == 'baz'
    end

    it "calls Raptor.formatter.example_failed when an error is raised" do
      with_mocha do
        error = RuntimeError.new('omgno!')
        Raptor.formatter.expects(:example_failed).with('foo', error)
        Unstable::Raptor::Example.new('foo') { raise error }.run
      end
    end

    it "calls Raptor.formatter.example_passed when no error is raised" do
      with_mocha do
        Raptor.formatter.expects(:example_passed).with('foo')
        Unstable::Raptor::Example.new('foo') { }.run
      end
    end

    it "runs in context" do
      example = Unstable::Raptor::Example.new('foo') { self }
      Raptor.formatter.stubs(:example_passed)
      example.run.should == example
    end

  end

end

describe Raptor::Formatters::Documentation do

  describe "#context_started" do

    it "prints the description, indented based on current depth" do
      with_mocha do
        Raptor.formatter.expects(:puts).with('    foo')
        Raptor.stubs(:depth).returns(2)
        Raptor.formatter.context_started('foo')
      end
    end

  end

  describe "#example_passed" do

    it "prints the description in green, indented based on current depth" do
      with_mocha do
        Raptor.formatter.expects(:puts).with("    \e[32mfoo\e[0m")
        Raptor.stubs(:depth).returns(2)
        Raptor.formatter.example_passed('foo')
      end
    end

  end

  describe "#example_failed" do

    it "prints the indented description in red and the exception" do
      with_mocha do
        Raptor.formatter.expects(:puts).with("    \e[31mfoo\e[0m")
        Raptor.formatter.expects(:puts).with('#<Raptor::Error: foo>')
        Raptor.stubs(:depth).returns(2)
        Raptor.formatter.example_failed('foo', Raptor::Error.new('foo'))
      end
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
