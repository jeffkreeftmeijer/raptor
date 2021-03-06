require File.expand_path('../../lib/raptor', __FILE__)
require 'mocha'

class Object
  include Mocha::API

  def clone_constants_from(victim)
    victim.constants.each do |constant|
      send(:remove_const, constant)
      const_set(constant, victim.const_get(constant).clone)
      victim.const_get(constant).clone_constants_from(const_get(constant))
    end
  end

  def with_mocha
    mocha_setup
    yield
    mocha_verify
    mocha_teardown
  end
end

module Unstable
  Raptor = ::Raptor.clone
  Object = ::Object.clone
  Kernel = ::Kernel.clone
end

Unstable::Raptor.clone_constants_from Raptor
Unstable::Raptor.context = Unstable::Raptor::Context
Unstable::Raptor.example = Unstable::Raptor::Example

require 'raptor'
