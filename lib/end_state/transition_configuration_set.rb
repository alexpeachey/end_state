module EndState
  class TransitionConfigurationSet

    def initialize
      @end_state_map = { any_state: {} }      # [start_state][event] = end_state
      @configuration_map = { any_state: {} }  # [start_state][end_state] = configuration
    end

    def add(start_state, end_state, configuration, event = nil)
      if event
        end_state_map[start_state] ||= {}
        end_state_map[start_state][event] = end_state
      end

      configuration_map[start_state] ||= {}
      configuration_map[start_state][end_state] = configuration
    end

    def get_configuration(start_state, end_state)
      local_map = configuration_map[start_state] || {}
      local_map[end_state] || configuration_map[:any_state][end_state]
    end

    def get_end_state(start_state, event)
      local_map = end_state_map[start_state] || {}
      local_map[event] || end_state_map[:any_state][event]
    end

    def start_states
      states = configuration_map.keys
      states.delete(:any_state)
      states += end_states unless configuration_map[:any_state].empty?
      states.uniq
    end

    def end_states
      configuration_map.map { |_, v| v.keys }.flatten.uniq
    end

    def events
      end_state_map.map { |_, v| v.keys }.flatten.uniq
    end

    def event_conflicts?(start_state, event)
      !!get_end_state(start_state, event) || (start_state == :any_state && events.include?(event))
    end

    def each &block
      all_transitions.each(&block)
    end

    private

    attr_reader :configuration_map, :end_state_map

    def all_transitions
      all_start_states = start_states

      configuration_map.map do |start_state, local_config|
        states = (start_state == :any_state) ? all_start_states : [start_state]
        states.map { |s| transitions_for s, local_config }
      end.flatten(2)
    end

    def transitions_for start_state, local_map
      local_map.map do |end_state, config|
        [start_state, end_state, config, event_for(start_state, end_state)]
      end
    end

    def event_for start_state, end_state
      (end_state_map[start_state] || {}).each do |k, v|
        return k if v == end_state
      end

      end_state_map[:any_state].each do |k, v|
        return k if v == end_state
      end

      nil
    end
  end
end
