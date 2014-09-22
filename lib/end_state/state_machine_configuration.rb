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
      transition_alias = state_map.delete(:as)
      transition_alias = transition_alias.to_sym unless transition_alias.nil?

      configuration = TransitionConfiguration.new
      yield configuration if block_given?

      state_map.each do |start_states, end_state|
        Array(start_states).each do |start_state|
          state_mapping = StateMapping[start_state.to_sym => end_state.to_sym]
          transition_configurations[state_mapping] = configuration
          add_event(transition_alias, state_mapping) unless transition_alias.nil?
        end
      end
    end

    def transition_configurations
      @transition_configurations ||= {}
    end

    def events
      @events ||= {}
    end

    def state_attribute(attribute)
      define_method(:state) { send(attribute.to_sym) }
      define_method(:state=) { |val| send("#{attribute}=".to_sym, val) }
    end

    def states
      (start_states + end_states).uniq
    end

    def start_states
      transition_configurations.keys.map(&:start_state).uniq
    end

    def end_states
      transition_configurations.keys.map(&:end_state).uniq
    end

    private

    def add_event(event, state_mapping)
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
