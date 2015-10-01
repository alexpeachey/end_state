module EndState
  class Graph < GraphViz
    attr_reader :machine, :nodes, :event_labels

    def initialize(machine, event_labels=true)
      @machine = machine
      @nodes = {}
      @event_labels = event_labels
      super machine.name.to_sym
    end

    def draw
      add_transitions
      self
    end

    private

    def add_transitions
      machine.transition_configurations.each do |start_state, end_state, _, event|
        add_transition(start_state, end_state, event)
      end
    end

    def add_transition start_state, end_state, event
      nodes[start_state] ||= add_node(start_state.to_s)
      nodes[end_state] ||= add_node(end_state.to_s)
      edge = add_edge nodes[start_state], nodes[end_state]
      edge[:label] = event.to_s if event && event_labels
    end
  end
end
