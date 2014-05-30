module EndState
  class Graph < GraphViz
    attr_reader :machine, :nodes

    def initialize(machine)
      @machine = machine
      @nodes = {}
      super machine.name.to_sym
    end

    def draw
      machine.transitions.keys.each do |t|
        left, right = t.to_a.flatten
        nodes[left] ||= add_node(left.to_s)
        nodes[right] ||= add_node(right.to_s)
        add_edge nodes[left], nodes[right]
      end
      self
    end
  end
end