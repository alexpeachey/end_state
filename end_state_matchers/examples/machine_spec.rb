$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'end_state_matchers'
require_relative './machine'

describe Machine do
  specify { expect(Machine).to have_transition(a: :b).with_guard(Easy).with_finalizer(NoOp) }
  specify { expect(Machine).to have_transition(a: :b).with_guards(Easy, Easy).with_finalizers(NoOp, NoOp) }
  specify { expect(Machine).not_to have_transition(a: :c) }
end
