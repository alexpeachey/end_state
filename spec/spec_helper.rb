require 'simplecov'
SimpleCov.start

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'end_state'
require 'end_state_matchers'

module RSpec
  module Matchers
    def fail_with(message)
      raise_error(RSpec::Expectations::ExpectationNotMetError, message)
    end
  end
end
