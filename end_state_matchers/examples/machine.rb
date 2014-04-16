require 'end_state'

class Easy < EndState::Guard
  def will_allow?
    true
  end
end

class Hard < EndState::Guard
  def will_allow?
    false
  end
end

class NoOp < EndState::Finalizer
  def call
    true
  end

  def rollback
    true
  end
end

class Machine < EndState::StateMachine
  transition a: :b do |t|
    t.guard Easy
    t.finalizer NoOp
  end
end
