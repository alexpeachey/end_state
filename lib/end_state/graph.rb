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
      machine.transitions.keys.each do |t|
        left, right = t.to_a.flatten
        nodes[left] ||= add_node(left.to_s)
        nodes[right] ||= add_node(right.to_s)
        edge = add_edge nodes[left], nodes[right]
        if event_labels
          event = machine.events.detect do |event, transition|
            transition.include? t
          end
          edge[:label] = event.first.to_s if event
        end
      end
      self
    end
  end
end