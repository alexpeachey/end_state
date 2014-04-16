module EndState
  class StateMachine < SimpleDelegator
    attr_accessor :failure_messages

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

    def self.state_attribute(attribute)
      define_method(:state) { send(attribute.to_sym) }
      define_method(:state=) { |val| send("#{attribute}=".to_sym, val) }
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

    def can_transition?(state)
      previous_state = self.state
      transition = self.class.transitions[{ previous_state => state }]
      return block_transistion(transition, state, :soft) unless transition
      transition.will_allow? state
    end

    def transition(state, mode = :soft)
      @failure_messages = []
      previous_state = self.state
      transition = self.class.transitions[{ previous_state => state }]
      return block_transistion(transition, state, mode) unless transition
      return guard_failed(state, mode) unless transition.allowed?(self)
      return false unless transition.action.new(self, state).call
      return finalize_failed(state, mode) unless transition.finalize(self, previous_state)
      true
    end

    def transition!(state)
      transition state, :hard
    end

    def method_missing(method, *args, &block)
      check_state = method.to_s[0..-2].to_sym
      return super unless self.class.states.include? check_state
      if method.to_s.end_with?('?')
        state == check_state
      elsif method.to_s.end_with?('!')
        transition check_state
      else
        super
      end
    end

    private

    def block_transistion(transition, state, mode)
      if self.class.end_states.include? state
        fail UnknownTransition, "The transition: #{object.state} => #{state} is unknown." if mode == :hard
        return false
      end
      fail UnknownState, "The state: #{state} is unknown." unless transition
    end

    def guard_failed(state, mode)
      return false unless mode == :hard
      fail GuardFailed, "The transition to #{state} was blocked: #{failure_messages.join(', ')}"
    end

    def finalize_failed(state, mode)
      return false unless mode == :hard
      fail FinalizerFailed, "The transition to #{state} was rolled back: #{failure_messages.join(', ')}"
    end
  end
end
