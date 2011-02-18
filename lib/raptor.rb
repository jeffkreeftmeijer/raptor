module Raptor

  class << self
    attr_writer :depth
    attr_accessor :formatter, :context, :example, :counter
  end

  def self.contexts
    @contexts ||= []
  end

  def self.depth
    @depth ||= 0
  end

  def self.run
    contexts.each { |context| context.setup }
    formatter.suite_started
    contexts.each { |context| context.run }
    formatter.suite_finished
    exit(counter[:failed_examples] == 0 ? 0 : 1)
  end

  class Should

    # When initializing a new `Raptor::Should` object, another object should be
    # passed to do comparisons on:
    #
    #    Raptor::Should.new('foo') 
    #    # <Raptor::Should:0xb74b30a4 @object="foo">
    #
    # An instance of `Raptor::Should` gets called when calling `#should` on any
    # object in your test suite:
    #
    #    'foo'.should
    #    # <Raptor::Should:0xb74b30a4 @object="foo">

    def initialize(object)
      @object = object
    end

    # Normally, `Object#==` compares `self` to the first argument:
    #
    #    'foo'.==('bar') # => false
    #    # foo is self, bar is the first argument
    #
    # In `Raptor::Should` we need to overwrite this to compare `@object`
    # (that's the object we passed when we created this `Raptor::Should`
    # object) to the first argument.
    #
    #    Raptor::Should.new('foo').==('bar') # => false
    #    # foo is @object, bar is the first argument.
    #
    # Besides returning the comparison's result, an error gets raised when the
    # result is false. This error can be rescued by the `Raptor::Example` object
    # later to make the example fail.

    def ==(comparison)
      result = @object == comparison
      raise(Error, "Expected #{comparison.inspect}, got #{@object.inspect}") unless result
      result
    end

  end

  class Context

    def contexts
      @contexts ||= []
    end

    def examples
      @examples ||= []
    end

    def hooks
      @hooks ||= {:before => [], :after => []}
    end

    def initialize(description, &block)
      @description = description
      @block = block
    end

    # Instead of directly running the test suite, Raptor has a setup phase
    # first. During this setup, every context gets looped through to register
    # it and its examples. This information can be used to let formatters give
    # information about the suite that's going to run, for example.
    #
    # The blocks get `instance_eval`-ed to run them inside the context. This
    # means that `this` is the parent context within the block and every
    # nested context or example inside that block is added to the parent 
    # context.
    #
    # After running the block, the context's nested contexts get set up too.

    def setup
      result = instance_eval(&@block)
      contexts.each { |context| context.setup }
      result
    end

    # After setting everything using `Raptor::Context#setup`, the context is
    # ready to run. `Raptor::Context#run` starts by calling the current
    # formatter's `#context_started` method, to let it know the context has
    # started running. After that, `Raptor.depth` gets incremented. Again, this
    # information can be used by formatters. The nested examples and contexts
    # receive the `#run` call too and the depth is restored to its original
    # value.

    def run
      Raptor.formatter.context_started(@description)
      Raptor.depth += 1

      examples.each do |example|
        hooks[:before].each { |hook| example.instance_eval(&hook) }
        example.run
        hooks[:after].each { |hook| example.instance_eval(&hook) }
      end

      contexts.each { |context| context.run }
      Raptor.depth -= 1
    end

    # To create a new context inside an existing context, the
    # `Raptor::Context#context` method is used. It will simply create a new
    # instance of `Raptor::Context` using the passed description and block and
    # add it to the current context's `#contexts` array. You can also use
    # `#describe` if you prefer. That's an alias for `#context`:
    #
    #    Context.new('foo') do
    #      context('bar') { }
    #      describe('baz') { }
    #    end

    def context(description, &block)
      context = self.class.new(description, &block)
      contexts << context
      context
    end

    alias_method :describe, :context

    # Examples can be defined inside contexts by using
    # `Raptor::Context#example`. It works exactly like the `#context` method
    # above, but creates an example instead of a context and increses the
    # example count in `Raptor.count`. If you prefer, you can use `#it` instead
    # of `#example`:
    #
    #    context 'foo' do
    #      example('bar') {}
    #      it('baz') {}
    #    end

    def example(description, &block)
      example = Raptor.example.new(description, &block)
      examples << example
      Raptor.counter[:examples] += 1
      example
    end

    alias_method :it, :example

    def hook(type, &block)
      hooks[type] << block
    end

  end

  class Example

    def initialize(description, &block)
      @description = description
      @block = block
    end

    def run
      begin
        result = instance_eval(&@block)
      rescue Object => exception
        Raptor.formatter.example_failed(@description, exception)
        Raptor.counter[:failed_examples] += 1
      else
        Raptor.formatter.example_passed(@description)
        Raptor.counter[:passed_examples] += 1
      ensure
        return result
      end
    end

  end

  module Formatter

    class Documentation

      def self.context_started(description)
        puts "#{'  ' * Raptor.depth}#{description}"
      end

      def self.example_passed(description)
        puts "#{'  ' * Raptor.depth}\e[32m#{description}\e[0m"
      end

      def self.example_failed(description, exception)
        puts "#{'  ' * Raptor.depth}\e[31m#{description}\e[0m"
        puts exception.inspect
      end

      def self.suite_started
        puts Raptor.counter.inspect
      end

      def self.suite_finished
        puts Raptor.counter.inspect
      end

    end

  end

  module Object

    def should
      Raptor::Should.new(self)
    end

  end

  class Error < StandardError
  end

  @formatter = Formatter::Documentation
  @context = Context
  @example = Example
  @counter = Hash.new(0)

end

module Kernel

  def context(description, &block)
    context = Raptor.context.new(description, &block)
    Raptor.contexts << context
    context
  end

  alias_method :describe, :context

end

Object.send :include, Raptor::Object
