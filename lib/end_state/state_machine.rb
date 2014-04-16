module EndState
  class StateMachine < SimpleDelegator
    def self.transition(state_map, &block)
      final_state = state_map.values.first
      transition = Transition.new(final_state)
      Array(state_map.keys.first).each do |state|
        transitions[{ state => final_state }] = transition
      end
      yield transition if block
    end

    def self.transitions
      @transitions ||= {}
    end

    def self.states
      (start_states + end_states).uniq
    end

    def self.start_states
      transitions.keys.map { |state_map| state_map.keys.first }.uniq
    end

    def self.end_states
      transitions.keys.map { |state_map| state_map.values.first }.uniq
    end

    def object
      __getobj__
    end

    def transition(state)
      previous_state = self.state
      transition = self.class.transitions[{ previous_state => state }]
      return block_transistion(transition, state) unless transition
      return false unless transition.guards_pass?(self)
      return false unless transition.action.new(self, state).call
      return false unless transition.finalize(self, previous_state)
      true
    end

    def method_missing(method, *args, &block)
      check_state = method.to_s[0..-2].to_sym
      super unless self.class.states.include? check_state
      if method.to_s.end_with?('?')
        state == check_state
      elsif method.to_s.end_with?('!')
        transition check_state
      else
        super
      end
    end

    private

    def block_transistion(transition, state)
      return false if self.class.end_states.include? state
      fail UnknownState, "The state: #{state} is unknown." unless transition
    end
  end
end
