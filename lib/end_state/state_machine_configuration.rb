module EndState
  module StateMachineConfiguration
    @initial_state = :__nil__
    @mode = :soft

    def initial_state
      @initial_state
    end

    def set_initial_state(state)
      @initial_state = state.to_sym
    end

    def treat_all_transitions_as_hard!
      @mode = :hard
    end

    def mode
      @mode
    end

    def store_states_as_strings!
      @store_states_as_strings = true
    end

    def store_states_as_strings
      !!@store_states_as_strings
    end

    def transition(state_map)
      event = state_map.delete(:as)
      event = event.to_sym unless event.nil?

      configuration = TransitionConfiguration.new
      yield configuration if block_given?

      state_map.each do |start_states, end_state|
        Array(start_states).each do |start_state|
          prevent_event_conflicts(start_state, event)
          transition_configurations.add(start_state, end_state, configuration, event)
        end
      end
    end

    def transition_configurations
      @transition_configurations ||= TransitionConfigurationSet.new
    end

    def state_attribute(attribute)
      define_method(:state) { send(attribute.to_sym) }
      define_method(:state=) { |val| send("#{attribute}=".to_sym, val) }
    end

    def events
      transition_configurations.events
    end

    def states
      (start_states + end_states).uniq
    end

    def start_states
      transition_configurations.start_states
    end

    def end_states
      transition_configurations.end_states
    end

    private

    def prevent_event_conflicts(start_state, event)
      return unless transition_configurations.event_conflicts?(start_state, event)
      fail EventConflict, "Attempting to define event '#{event}' on state '#{start_state}', but it is already defined. (Check duplicates and use of 'any_state')"
    end
  end
end
