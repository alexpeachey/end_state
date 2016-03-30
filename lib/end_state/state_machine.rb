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
      __sm_reset_messages
      return false unless __sm_transition_configuration_for(state.to_sym, end_state.to_sym)
      __sm_transition_for(end_state.to_sym).allowed?(params)
    end

    def transition(end_state, params = {}, mode = self.class.mode)
      __sm_reset_messages
      return __sm_block_transistion(end_state.to_sym, mode) unless __sm_transition_configuration_for(state.to_sym, end_state.to_sym)
      __sm_transition_for(end_state.to_sym, mode).call(params)
    end

    def transition!(end_state, params = {})
      transition end_state.to_sym, params, :hard
    end

    def method_missing(method, *args, &block)
      return super unless __sm_is_method?(method)
      return __sm_predicate(method) if __sm_is_state_predicate?(method)
      __sm_event_transition __sm_event(method), args[0] || {}, __sm_event_mode(method)
    end

    private

    def __sm_is_method?(method)
      __sm_is_state_predicate?(method) || __sm_is_event?(method)
    end

    def __sm_predicate(method)
      __sm_current_state? __sm_extract_state(method)
    end

    def __sm_extract_state(method)
      method.to_s[0..-2].to_sym
    end

    def __sm_event(method)
      method.to_s.gsub('!','').to_sym
    end

    def __sm_event_mode(method)
      return :hard if method.to_s.end_with?('!')
      __sm_actual_mode(:soft)
    end

    def __sm_is_state_predicate?(method)
      method.to_s.end_with?('?') && self.class.states.include?(__sm_extract_state(method))
    end

    def __sm_is_event?(method)
      self.class.events.include? __sm_event(method)
    end

    def __sm_current_state?(end_state)
      state.to_sym == end_state
    end

    def __sm_event_transition(event, params, mode)
      end_state = __sm_state_for_event(event, mode)
      return false if end_state == :__invalid_event__
      transition end_state, params, mode
    end

    def __sm_actual_mode(mode)
      return :hard if self.class.mode == :hard
      mode
    end

    def __sm_state_for_event(event, mode)
      self.class.transition_configurations.get_end_state(state.to_sym, event) || __sm_invalid_event(event, mode)
    end

    def __sm_invalid_event(event, mode)
      fail InvalidTransition, "Transition by event: #{event} is invalid." if mode == :hard
      :__invalid_event__
    end

    def __sm_transition_configuration_for(start_state, end_state)
      self.class.transition_configurations.get_configuration(start_state, end_state)
    end

    def __sm_transition_for(end_state, mode = self.class.mode)
      start_state = state.to_sym
      end_state = end_state.to_sym
      configuration = __sm_transition_configuration_for(start_state, end_state)
      mode = __sm_actual_mode(mode)
      Transition.new(self, start_state, end_state, configuration, mode)
    end

    def __sm_block_transistion(state, mode)
      if self.class.end_states.include? state
        fail InvalidTransition, "The transition: #{object.state} => #{state} is invalid." if mode == :hard
        return false
      end
      fail UnknownState, "The state: #{state} is unknown."
    end

    def __sm_reset_messages
      @failure_messages = []
      @success_messages = []
    end
  end
end
