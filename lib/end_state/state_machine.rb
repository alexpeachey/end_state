module EndState
  class StateMachine < SimpleDelegator
    def self.transition(state, &block)
      transition = Transition.new(state)
      transitions[state] = transition
      yield transition if block
    end

    def self.transitions
      @transitions ||= {}
    end

    def object
      __getobj__
    end

    def transition(state)
      previous_state = self.state
      transition = self.class.transitions[state]
      fail UnknownState, "The state: #{state} is unknown." unless transition
      return false unless transition.guards_pass?(self)
      return false unless transition.action.new(self, state).call
      return false unless transition.finalize(self, previous_state)
      true
    end

    def method_missing(method, *args, &block)
      if method.to_s.end_with?('?')
        check_state = method.to_s[0..-2].to_sym
        super unless self.class.transitions.keys.include? check_state
        state == check_state
      else
        super
      end
    end
  end
end
