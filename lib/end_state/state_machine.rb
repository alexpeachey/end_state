module EndState
  class StateMachine < SimpleDelegator
    extend StateMachineConfiguration

    attr_accessor :failure_messages, :success_messages

    def initialize(object)
      super
      Action.new(self, self.class.initial_state).call if self.state.nil?
    end

    def object
      __getobj__
    end

    def can_transition?(state, params = {})
      return __sm_block_transistion(state, :soft) unless __sm_transition_configuration_for(self.state, state)
      __sm_transition_for(state).will_allow?(params)
    end

    def transition(state, params = {}, mode = self.class.mode)
      __sm_reset_messages
      return __sm_block_transistion(state, mode) unless __sm_transition_configuration_for(self.state, state)
      __sm_transition_for(state, mode).call(params)
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
      state_mappings = self.class.events[event]
      return false unless state_mappings
      state_mappings.each do |state_mapping|
        return state_mapping.end_state if state_mapping.matches_start_state?(state.to_sym)
      end
      return __sm_invalid_event(event, mode)
    end

    def __sm_invalid_event(event, mode)
      fail InvalidTransition, "Transition by event: #{event} is invalid." if mode == :hard
      :__invalid_event__
    end

    def __sm_transition_configuration_for(from, to)
      self.class.transition_configurations[{ from => to }] ||
      self.class.transition_configurations[{ any_state: to }]
    end

    def __sm_transition_for(state, mode = self.class.mode)
      from = self.state
      to = state.to_sym
      configuration = __sm_transition_configuration_for(from, to)
      mode = __sm_actual_mode(mode)
      Transition.new(self, from, to, configuration, mode)
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
