module EndState
  class StateMachine < SimpleDelegator
    attr_accessor :failure_messages

    def self.transition(state_map)
      initial_states = Array(state_map.keys.first)
      final_state = state_map.values.first
      transition_alias = state_map[:as] if state_map.keys.length > 1
      transition = Transition.new(final_state)
      initial_states.each do |state|
        transitions[{ state => final_state }] = transition
      end
      unless transition_alias.nil?
        aliases[transition_alias] = final_state
      end
      yield transition if block_given?
    end

    def self.transitions
      @transitions ||= {}
    end

    def self.aliases
      @aliases ||= {}
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

    def self.transition_state_for(check_state)
      return check_state if states.include? check_state
      return aliases[check_state] if aliases.keys.include? check_state
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

    def transition(state, params = {}, mode = :soft)
      @failure_messages = []
      previous_state = self.state
      transition = self.class.transitions[{ previous_state => state }]
      return block_transistion(transition, state, mode) unless transition
      return guard_failed(state, mode) unless transition.allowed?(self, params)
      return false unless transition.action.new(self, state).call
      return finalize_failed(state, mode) unless transition.finalize(self, previous_state, params)
      true
    end

    def transition!(state, params = {})
      transition state, params, :hard
    end

    def method_missing(method, *args, &block)
      check_state = method.to_s[0..-2].to_sym
      check_state = self.class.transition_state_for(check_state)
      return super if check_state.nil?
      if method.to_s.end_with?('?')
        state == check_state
      elsif method.to_s.end_with?('!')
        transition check_state, args[0]
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
