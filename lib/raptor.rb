module Raptor

  class << self
    attr_writer :depth
    attr_accessor :formatter, :example, :counter
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

    def initialize(description, &block)
      @description = description
      @block = block
    end

    # Instead of directly running the test suite, Raptor has a setup phase
    # first. During this setup, every context gets looped through to register
    # it and its examples. Using this information, formatters can give
    # information about the suite that's going to run.
    #
    # The blocks get `instance_eval`-ed to run them inside the context. This
    # means that `this` is the parent context within the block. After that,
    # every nested context gets set up too 

    def setup
      result = instance_eval(&@block)
      contexts.each { |context| context.setup }
      result
    end

    def run
      Raptor.formatter.context_started(@description)
      Raptor.depth += 1
      examples.each { |example| example.run }
      contexts.each { |context| context.run }
      Raptor.depth -= 1
    end

    def context(description, &block)
      context = Raptor::Context.new(description, &block)
      contexts << context
      context
    end

    alias_method :describe, :context

    def example(description, &block)
      example = Raptor.example.new(description, &block)
      examples << example
      Raptor.counter[:examples] += 1
      example
    end

    alias_method :it, :example

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

  class Error < StandardError
  end

  @formatter = Formatter::Documentation
  @example = Example
  @counter = Hash.new(0)

end

class Object

  def should
    Raptor::Should.new(self)
  end

end

module Kernel

  def context(description, &block)
    context = Raptor::Context.new(description, &block)
    Raptor.contexts << context
    context
  end

  alias_method :describe, :context

end
