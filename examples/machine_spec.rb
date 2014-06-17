$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'end_state'
require 'end_state_matchers'

class Easy < EndState::Guard
  def will_allow?
    true
  end
end

class NoOp < EndState::Concluder
  def call
    true
  end
end

class Machine < EndState::StateMachine
  transition a: :b do |t|
    t.guard Easy
    t.concluder NoOp
  end
end

describe Machine do
  specify { expect(Machine).to have_transition(a: :b).with_guard(Easy).with_concluder(NoOp) }
  specify { expect(Machine).to have_transition(a: :b).with_guards(Easy, Easy).with_concluders(NoOp, NoOp) }
  specify { expect(Machine).not_to have_transition(a: :c) }
end
