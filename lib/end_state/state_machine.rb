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
      transition_alias = transition_alias.to_sym unless transition_alias.nil?

      configuration = TransitionConfiguration.new
      yield configuration if block_given?

      state_map.each do |start_states, end_state|
        Array(start_states).each do |start_state|
          state_mapping = StateMapping[start_state.to_sym => end_state.to_sym]
          transition_configurations[state_mapping] = configuration
          __sm_add_event(transition_alias, state_mapping) unless transition_alias.nil?
        end
      end
    end

    def self.transition_configurations
      @transition_configurations ||= {}
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
      transition_configurations.keys.map(&:start_state).uniq
    end

    def self.end_states
      transition_configurations.keys.map(&:end_state).uniq
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
      message = self.class.transition_configurations[self.class.events[event].first].blocked_event_message
      @failure_messages = [message] if message
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

    def self.__sm_add_event(event, state_mapping)
      events[event] ||= []
      conflicting_mapping = events[event].find{ |sm| sm.conflicts?(state_mapping) }
      if conflicting_mapping
        message =
          "Attempting to define :#{event} as transitioning from " \
          ":#{state_mapping.start_state} => :#{state_mapping.end_state} when " \
          ":#{conflicting_mapping.start_state} => :#{conflicting_mapping.end_state} already exists. " \
          "You cannot define multiple transitions from a single state with the same event name."

        fail EventConflict, message
      end
      events[event] << state_mapping
    end
  end
end
