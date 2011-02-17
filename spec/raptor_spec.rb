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

    it "returns Raptor::Formatter::Documentation by default" do
      Unstable::Raptor.formatter.to_s.should == 'Raptor::Formatter::Documentation'
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
      Unstable::Raptor.counter.delete('foo').should == 'bar'
    end

    it "returns 0 by default" do
      Unstable::Raptor.counter['bar'].should == 0
    end

  end

  describe ".run" do

    it "sets up the contexts" do
      with_mocha do
        Unstable::Raptor.formatter.stubs(:suite_started)
        Unstable::Raptor.formatter.stubs(:suite_finished)
        Unstable::Raptor.stubs(:exit)

        Unstable::Raptor.instance_variable_set(
          :@contexts,
          [Unstable::Raptor::Context.new('foo') {}] * 3
        )

        Unstable::Raptor.contexts.each do |context|
          context.stubs(:run)
          context.expects(:setup)
        end

        Unstable::Raptor.run
      end
    end

    it "runs the contexts" do
      with_mocha do
        Unstable::Raptor.formatter.stubs(:suite_started)
        Unstable::Raptor.formatter.stubs(:suite_finished)
        Unstable::Raptor.stubs(:exit)

        Unstable::Raptor.instance_variable_set(
          :@contexts,
          [Unstable::Raptor::Context.new('foo') {}] * 3
        )

        Unstable::Raptor.contexts.each { |context| context.expects(:run) }

        Unstable::Raptor.run
      end
    end

    it "calls Raptor.formatter.suite_started/suite_finished" do
      with_mocha do
        Unstable::Raptor.stubs(:contexts).returns([])
        Unstable::Raptor.formatter.expects(:suite_started)
        Unstable::Raptor.formatter.expects(:suite_finished)
        Unstable::Raptor.stubs(:exit)

        Unstable::Raptor.run
      end
    end

    it "exits with 0 as the exit code when there are no failures" do
      with_mocha do
        Unstable::Raptor.stubs(:contexts).returns([])
        Unstable::Raptor.formatter.stubs(:suite_started)
        Unstable::Raptor.formatter.stubs(:suite_finished)

        Unstable::Raptor.expects(:exit).with(0)
        Unstable::Raptor.run
      end
    end

    it "exits with 1 as the exit code when there are failures" do
      with_mocha do
        Unstable::Raptor.stubs(:contexts).returns([])
        Unstable::Raptor.formatter.stubs(:suite_started)
        Unstable::Raptor.formatter.stubs(:suite_finished)

        Unstable::Raptor.stubs(:counter).returns({:failed_examples => 3})
        Unstable::Raptor.expects(:exit).with(1)
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

  describe "#setup" do

    it "runs the block" do
      with_mocha do
        context = Unstable::Raptor::Context.new('foo') { 'baz' }
        context.setup.should == 'baz'
      end
    end

    it "runs in context" do
      context = Unstable::Raptor::Context.new('foo') { self }
      context.setup.should == context
    end

    it "sets up nested contexts" do
      called = false
      parent_context = Unstable::Raptor::Context.new('foo') {}
      context = parent_context.context('bar') { called = true }
      parent_context.setup
      called.should == true
    end

  end

  describe "#run" do

    it "runs nested contexts" do
      with_mocha do
        Raptor.formatter.stubs(:context_started)
        parent_context = Unstable::Raptor::Context.new('foo') {}
        context = parent_context.context('bar') { }
        context.expects(:run)
        parent_context.run
      end
    end

    it "runs nested examples" do
      with_mocha do
        Raptor.counter.stubs(:[]=)
        Raptor.formatter.stubs(:context_started)
        Raptor.formatter.stubs(:example_passed)
        called = false
        context = Unstable::Raptor::Context.new('foo') {}
        example = context.example('bar') { called = true }
        context.run
        called.should == true
      end
    end

    it "increases Raptor.depth while running nested examples" do
      with_mocha do
        Raptor.formatter.stubs(:context_started)
        Raptor.formatter.stubs(:example_passed)
        Raptor.counter.stubs(:[]=)

        original_depth, depth = Raptor.depth, 0

        context = Unstable::Raptor::Context.new('foo') {}
        example = context.example('bar') { depth = Raptor.depth }

        context.run

        depth.should == original_depth + 1
        Raptor.depth.should == original_depth
      end
    end

    it "runs before and after hooks" do
      with_mocha do
        Raptor.formatter.stubs(:context_started)
        Raptor.formatter.stubs(:example_passed)
        Raptor.counter.stubs(:[]=)

        result = []

        context = Unstable::Raptor::Context.new('foo')
        context.hook(:before) { result << :before }
        context.example(:example) { result << :example }
        context.hook(:after) { result << :after }

        context.run

        result.should == [:before, :example, :after]
      end
    end

    it "runs multiple before hooks" do
      with_mocha do
        Raptor.formatter.stubs(:context_started)
        Raptor.formatter.stubs(:example_passed)
        Raptor.counter.stubs(:[]=)

        result = []

        context = Unstable::Raptor::Context.new('foo')
        context.hook(:before) { result << :before }
        context.hook(:before) { result << :before }
        context.example(:example) { result << :example }

        context.run

        result.should == [:before, :before, :example]
      end
    end

    it "runs hooks within the example instance" do
      with_mocha do
        Raptor.formatter.stubs(:context_started)
        Raptor.formatter.stubs(:example_passed)

        context = Unstable::Raptor::Context.new('foo')
        context.hook(:before) { yeah! }
        example = context.example('bar') { }

        example.expects(:yeah!)
        context.run
      end
    end

    it "increases Raptor.depth while running nested contexts" do
      with_mocha do
        Raptor.formatter.stubs(:context_started)
        Raptor.formatter.stubs(:example_passed) 

        parent_context = Unstable::Raptor::Context.new('foo') {}
        context = parent_context.context('bar') { }

        Raptor.stubs(:depth).returns(1)
        Raptor.expects(:depth=).with(2).twice
        Raptor.expects(:depth=).with(0).twice

        parent_context.run
      end
    end

    it "calls Raptor.formatter#context_started" do
      with_mocha do
        Raptor.formatter.expects(:context_started).with('foo')

        Unstable::Raptor::Context.new('foo') {}.run
      end
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
      with_mocha do
        Raptor.counter.stubs(:[]=)
        context = Unstable::Raptor::Context.new('foo')
        example = context.example('foo') { 'bar' }
        example.class.should == Raptor::Example
        example.instance_variable_get(:@description).should == 'foo'
        example.instance_variable_get(:@block).call.should == 'bar'
      end
    end

    it "adds an example to context.examples" do
      with_mocha do
        Raptor.counter.stubs(:[]=)
        context = Unstable::Raptor::Context.new('foo')
        example = context.example('foo')
        context.examples.pop.should == example
      end
    end

    it "increases Raptor.counter[:examples]" do
      with_mocha do
        Raptor.counter.expects(:[]=).with(
          :examples,
          Raptor.counter[:examples] + 1
        )

        context = Unstable::Raptor::Context.new('foo')

        example = context.example('foo')
      end
    end

  end

  describe "#it" do

    it "is an alias for #example" do
      with_mocha do
        Raptor.counter.stubs(:[]=)
        context = Unstable::Raptor::Context.new('foo')
        context.it('foo').class.should == Raptor::Example
      end
    end

  end

  describe "#hook" do

    it "adds a before hook to context.hooks" do
      context = Unstable::Raptor::Context.new('foo') {}
      context.hook(:before) { true }
      context.hooks[:before].length.should == 1
      context.hooks[:before].first.call.should == true
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
      with_mocha do
        Raptor.formatter.stubs(:example_passed)
        Raptor.counter.stubs(:[]=)
        example = Unstable::Raptor::Example.new('foo') { 'baz' }
        example.run.should == 'baz'
      end
    end

    it "runs in context" do
      with_mocha do
        Raptor.formatter.stubs(:example_passed)
        Raptor.counter.stubs(:[]=)
        example = Unstable::Raptor::Example.new('foo') { self }
        example.run.should == example
      end
    end

    context "when no error is raised" do

      it "calls Raptor.formatter.example_passed" do
        with_mocha do
          Raptor.counter.stubs(:[]=)
          Raptor.formatter.expects(:example_passed).with('foo')

          Unstable::Raptor::Example.new('foo') { }.run
        end
      end

      it "increases Raptor.counter[:passed_examples]" do
        with_mocha do
          Raptor.formatter.stubs(:example_passed)
          Raptor.counter.expects(:[]=).with(
            :passed_examples,
            Raptor.counter[:passed_examples] + 1
          )

          Unstable::Raptor::Example.new('foo') { }.run
        end
      end

    end

    context "when an error is raised" do

      it "calls Raptor.formatter.example_failed" do
        with_mocha do
          Raptor.counter.stubs(:[]=)
          error = RuntimeError.new('omgno!')
          Raptor.formatter.expects(:example_failed).with('foo', error)

          Unstable::Raptor::Example.new('foo') { raise error }.run
        end
      end

      it "increases Raptor.counter[:failed_examples]" do
        with_mocha do
          Raptor.formatter.stubs(:example_failed)
          Raptor.counter.expects(:[]=).with(
            :failed_examples,
            Raptor.counter[:failed_examples] + 1
          )

          Unstable::Raptor::Example.new('foo') { raise 'omgno' }.run
        end
      end

    end

  end

end

describe Raptor::Formatter::Documentation do

  describe "#context_started" do

    it "prints the description, indented based on current depth" do
      with_mocha do
        Raptor.stubs(:depth).returns(2)
        Raptor::Formatter::Documentation.expects(:puts).with('    foo')
        Raptor::Formatter::Documentation.context_started('foo')
      end
    end

  end

  describe "#example_passed" do

    it "prints the description in green, indented based on current depth" do
      with_mocha do
        Raptor.stubs(:depth).returns(2)
        Raptor::Formatter::Documentation.expects(:puts).with("    \e[32mfoo\e[0m")
        Raptor::Formatter::Documentation.example_passed('foo')
      end
    end

  end

  describe "#example_failed" do

    it "prints the indented description in red and the exception" do
      with_mocha do
        Raptor.stubs(:depth).returns(2)
        Raptor::Formatter::Documentation.expects(:puts).with("    \e[31mfoo\e[0m")
        Raptor::Formatter::Documentation.expects(:puts).with('#<Raptor::Error: foo>')

        Raptor::Formatter::Documentation.example_failed('foo', Raptor::Error.new('foo'))
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
