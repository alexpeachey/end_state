require 'spec_helper'

describe EndState::Graph do
  class TestMachine < EndState::StateMachine
    transition a: :b
    transition b: :c
    transition c: :d, as: :go
    transition any_state: :a
    transition any_state: :e, as: :exit
  end

  subject(:graph) { EndState::Graph.new(TestMachine) }

  describe '#draw' do
    let(:description) { graph.draw.to_s }

    it 'contains all the nodes' do
      ['a [label = "a"];', 'b [label = "b"];', 'c [label = "c"];', 'd [label = "d"];', 'e [label = "e"];'].each do |s|
        expect(description).to include(s)
      end
    end

    it 'contains all the edges without labels' do
      ['a -> b;', 'b -> c;', 'a -> a;', 'b -> a;', 'c -> a;', 'd -> a;', 'e -> a;'].each do |s|
        expect(description).to include(s)
      end
    end

    it 'contains all the edges with labels' do
      ['c -> d [label = "go"];', 'a -> e [label = "exit"];', 'b -> e [label = "exit"];', 'c -> e [label = "exit"];', 'd -> e [label = "exit"];', 'e -> e [label = "exit"];'].each do |s|
        expect(description).to include(s)
      end
    end
  end
end
