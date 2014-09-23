module EndState
  class TransitionConfigurationSet

    def initialize
      @events = { any_state: {} }   # [start_state][event] = end_state
      @configs = { any_state: {} }  # [start_state][end_state] = configuration
    end

    def add(start_state, end_state, configuration, event = nil)
      if event
        @events[start_state] ||= {}
        @events[start_state][event] = end_state
      end

      @configs[start_state] ||= {}
      @configs[start_state][end_state] ||= configuration
    end

    def get_by_end_state(start_state, end_state)
      local_map = @configs[start_state] || {}
      local_map[end_state] || @configs[:any_state][end_state]
    end

    def get_by_event(start_state, event)
      local_map = @events[start_state] || {}
      local_map[event] || @events[:any_state][event]
    end

    def start_states
      states = @configs.keys
      states.delete(:any_state)
      states += end_states unless @configs[:any_state].empty?
      states.uniq
    end

    def end_states
      @configs.map { |k, v| v.keys }.flatten.uniq
    end

    def events
      @events.map { |k, v| v.keys }.flatten.uniq
    end

    def event_conflicts?(start_state, event)
      !!get_by_event(start_state, event) || (start_state == :any_state && events.include?(event))
    end

    def each &block
      all_transitions.each &block
    end

    private

    def all_transitions
      all_start_states = start_states

      @configs.map do |start_state, local_config|
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
      (@events[start_state] || {}).each do |k, v|
        return k if v == end_state
      end

      @events[:any_state].each do |k, v|
        return k if v == end_state
      end

      nil
    end
  end
end
