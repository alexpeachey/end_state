module EndState
  class Graph
    def initialize(machine, event_labels=true)
      @machine = machine
      @event_labels = event_labels
    end

    def draw
      self
    end
  end
end
