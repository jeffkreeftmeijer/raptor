require File.expand_path('../../lib/raptor', __FILE__)

require 'mocha'

class Object
  include Mocha::API
end
