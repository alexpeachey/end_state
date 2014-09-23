module EndState
  class StateMachine < SimpleDelegator
    extend StateMachineConfiguration

    attr_accessor :failure_messages, :success_messages

    def initialize(object)
      super
      Action.new(self, self.class.initial_state).call if state.nil?
    end

    def object
      __getobj__
    end

    def can_transition?(end_state, params = {})
      return false unless transition_configuration_for(state, end_state)
      transition_for(end_state).will_allow?(params)
    end

    def transition(end_state, params = {}, mode = self.class.mode)
      reset_messages
      return block_transistion(end_state, mode) unless transition_configuration_for(state, end_state)
      transition_for(end_state, mode).call(params)
    end

    def transition!(end_state, params = {})
      transition end_state, params, :hard
    end

    def method_missing(method, *args, &block)
      if is_state_predicate?(method)
        current_state? extract_state(method)
      elsif is_event?(method)
        event, mode = extract_event_and_mode(method)
        event_transition event, args[0] || {}, mode
      else
        super
      end
    end

    private

    def extract_state(method)
      method.to_s[0..-2].to_sym
    end

    def extract_event_and_mode(method)
      if method.to_s.end_with?('!')
        [method.to_s[0..-2].to_sym, :hard]
      else
        [method.to_sym, actual_mode(:soft)]
      end
    end

    def is_state_predicate?(method)
      method.to_s.end_with?('?') && self.class.states.include?(extract_state(method))
    end

    def is_event?(method)
      event, mode = extract_event_and_mode(method)
      self.class.events.include?(event)
    end

    def current_state?(end_state)
      state.to_sym == end_state
    end

    def event_transition(event, params, mode)
      end_state = state_for_event(event, mode)
      return false if end_state == :__invalid_event__
      transition end_state, params, mode
    end

    def actual_mode(mode)
      return :hard if self.class.mode == :hard
      mode
    end

    def state_for_event(event, mode)
      self.class.transition_configurations.get_by_event(state.to_sym, event) || invalid_event(event, mode)
    end

    def invalid_event(event, mode)
      fail InvalidTransition, "Transition by event: #{event} is invalid." if mode == :hard
      :__invalid_event__
    end

    def transition_configuration_for(start_state, end_state)
      self.class.transition_configurations.get_by_end_state(start_state, end_state)
    end

    def transition_for(end_state, mode = self.class.mode)
      start_state = state.to_sym
      end_state = end_state.to_sym
      configuration = transition_configuration_for(start_state, end_state)
      mode = actual_mode(mode)
      Transition.new(self, start_state, end_state, configuration, mode)
    end

    def block_transistion(state, mode)
      if self.class.end_states.include? state
        fail InvalidTransition, "The transition: #{object.state} => #{state} is invalid." if mode == :hard
        return false
      end
      fail UnknownState, "The state: #{state} is unknown."
    end

    def reset_messages
      @failure_messages = []
      @success_messages = []
    end
  end
end
