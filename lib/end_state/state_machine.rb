module EndState
  class StateMachine < SimpleDelegator
    attr_accessor :failure_messages, :success_messages

    def initialize(object)
      super
      Action.new(self, self.class.initial_state).call if self.state.nil?
    end

    @initial_state = :__nil__
    @mode = :soft

    def self.initial_state
      @initial_state
    end

    def self.set_initial_state(state)
      @initial_state = state.to_sym
    end

    def self.treat_all_transitions_as_hard!
      @mode = :hard
    end

    def self.mode
      @mode
    end

    def self.store_states_as_strings!
      @store_states_as_strings = true
    end

    def self.store_states_as_strings
      !!@store_states_as_strings
    end

    def self.transition(state_map)
      transition_alias = state_map.delete(:as)
      events[transition_alias.to_sym] ||= [] unless transition_alias.nil?

      state_map.each do |initial_states, final_state|
        transition = Transition.new(final_state)

        Array(initial_states).each do |initial_state|
          key = { initial_state.to_sym => final_state.to_sym }
          transitions[key] = transition
          events[transition_alias.to_sym] << key unless transition_alias.nil?
        end

        yield transition if block_given?
      end
    end

    def self.transitions
      @transitions ||= {}
    end

    def self.events
      @events ||= {}
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

    def can_transition?(state, params = {})
      previous_state = self.state.to_sym
      state = state.to_sym
      transition = __sm_transition_for(previous_state, state)
      return __sm_block_transistion(transition, state, :soft) unless transition
      transition.will_allow? state, params
    end

    def transition(state, params = {}, mode = self.class.mode)
      @failure_messages = []
      @success_messages = []
      previous_state = self.state ? self.state.to_sym : self.state
      state = state.to_sym
      transition = __sm_transition_for(previous_state, state)
      mode = __sm_actual_mode(mode)
      return __sm_block_transistion(transition, state, mode) unless transition
      return __sm_guard_failed(state, mode) unless transition.allowed?(self, params)
      return false unless transition.action.new(self, state).call
      return __sm_conclude_failed(state, mode) unless transition.conclude(self, previous_state, params)
      true
    end

    def transition!(state, params = {})
      transition state, params, :hard
    end

    def method_missing(method, *args, &block)
      return super unless __sm_predicate_or_event?(method)
      return __sm_current_state?(method) if __sm_state_predicate(method)
      new_state, mode = __sm_event(method)
      return false if new_state == :__invalid_event__
      transition new_state, (args[0] || {}), mode
    end

    private

    def __sm_predicate_or_event?(method)
      __sm_state_predicate(method) ||
      __sm_event(method)
    end

    def __sm_state_predicate(method)
      state = method.to_s[0..-2].to_sym
      return unless self.class.states.include?(state) && method.to_s.end_with?('?')
      state
    end

    def __sm_event(method)
      event = __sm_state_for_event(method.to_sym, __sm_actual_mode(:soft))
      return event, __sm_actual_mode(:soft) if event
      return unless method.to_s.end_with?('!')
      event = __sm_state_for_event(method.to_s[0..-2].to_sym, :hard)
      return event, :hard if event
      nil
    end

    def __sm_actual_mode(mode)
      return :hard if self.class.mode == :hard
      mode
    end

    def __sm_current_state?(method)
      state.to_sym == __sm_state_predicate(method)
    end

    def __sm_state_for_event(event, mode)
      transitions = self.class.events[event]
      return false unless transitions
      start_states = transitions.map { |t| t.keys.first }
      return __sm_invalid_event(event, mode) unless start_states.include?(state.to_sym) || start_states.include?(:any_state)
      transitions.first.values.first
    end

    def __sm_invalid_event(event, mode)
      fail InvalidTransition, "Transition by event: #{event} is invalid." if mode == :hard
      message = self.class.transitions[self.class.events[event].first].blocked_event_message
      @failure_messages = [message] if message
      :__invalid_event__
    end

    def __sm_transition_for(from, to)
      self.class.transitions[{ from => to }] ||
      self.class.transitions[{ any_state: to }]
    end

    def __sm_block_transistion(transition, state, mode)
      if self.class.end_states.include? state
        fail InvalidTransition, "The transition: #{object.state} => #{state} is invalid." if mode == :hard
        return false
      end
      fail UnknownState, "The state: #{state} is unknown."
    end

    def __sm_guard_failed(state, mode)
      return false unless mode == :hard
      fail GuardFailed, "The transition to #{state} was blocked: #{failure_messages.join(', ')}"
    end

    def __sm_conclude_failed(state, mode)
      return false unless mode == :hard
      fail ConcluderFailed, "The transition to #{state} was rolled back: #{failure_messages.join(', ')}"
    end
  end
end
