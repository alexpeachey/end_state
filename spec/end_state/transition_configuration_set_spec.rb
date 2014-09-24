require 'spec_helper'
require 'ostruct'

module EndState
  describe TransitionConfigurationSet do
    subject(:set) { TransitionConfigurationSet.new }
    let(:config1) { double :config }
    let(:config2) { double :config }
    let(:config3) { double :config }
    let(:config4) { double :config }

    describe 'without any configurations added' do
      context '#get_by_end_state' do
        it 'returns nil' do
          expect(set.get_by_end_state(:a, :b)).to be_nil
        end
      end

      context '#get_by_event' do
        it 'returns nil' do
          expect(set.get_by_event(:a, :advance)).to be_nil
        end
      end

      context '#each' do
        it 'iterates over []' do
          expect{ |b| set.each(&b) }.to_not yield_control
        end
      end

      context '#start_states' do
        it 'returns []' do
          expect(set.start_states).to eql []
        end
      end

      context '#end_states' do
        it 'returns []' do
          expect(set.end_states).to eql []
        end
      end

      context '#events' do
        it 'returns []' do
          expect(set.events).to eql []
        end
      end
    end

    describe 'with direct transitions set' do
      before do
        set.add(:a, :b, config1)
        set.add(:b, :c, config2, :advance)
        set.add(:c, :a, config3, :reset)
      end

      context '#get_by_end_state' do
        it 'returns nil if the configuration does not exist' do
          expect(set.get_by_end_state(:b, :a)).to be_nil
          expect(set.get_by_end_state(:c, :b)).to be_nil
        end

        it 'returns the configuration if it exists' do
          expect(set.get_by_end_state(:a, :b)).to eql config1
          expect(set.get_by_end_state(:b, :c)).to eql config2
          expect(set.get_by_end_state(:c, :a)).to eql config3
        end
      end

      context '#get_by_event' do
        it 'returns nil if the configuration does not exist' do
          expect(set.get_by_event(:b, :reset)).to be_nil
          expect(set.get_by_event(:c, :advance)).to be_nil
        end

        it 'returns the configuration if it exists' do
          expect(set.get_by_event(:b, :advance)).to eql :c
          expect(set.get_by_event(:c, :reset)).to eql :a
        end
      end

      context '#each' do
        it 'iterates over all transitions' do
          expect{ |b| set.each(&b) }.to yield_control.exactly(3)
          expect(set.each).to match_array [
            [:a, :b, config1, nil], [:b, :c, config2, :advance], [:c, :a, config3, :reset]
          ]
        end
      end

      context '#start_states' do
        it 'returns all the start_states' do
          expect(set.start_states).to match_array [:a, :b, :c]
        end
      end

      context '#end_states' do
        it 'returns all the end_states' do
          expect(set.end_states).to match_array [:a, :b, :c]
        end
      end

      context '#events' do
        it 'returns all the events' do
          expect(set.events).to match_array [:advance, :reset]
        end
      end

      context "#event_conflicts?" do
        it 'returns false if the event would not conflict with an existing event' do
          expect(set.event_conflicts?(:a, :advance)).to eql false
          expect(set.event_conflicts?(:b, :reset)).to eql false
          expect(set.event_conflicts?(:c, :other)).to eql false
          expect(set.event_conflicts?(:any_state, :other)).to eql false
        end

        it 'returns true if the event would conflict with an existing event' do
          expect(set.event_conflicts?(:b, :advance)).to eql true
          expect(set.event_conflicts?(:c, :reset)).to eql true
          expect(set.event_conflicts?(:any_state, :advance)).to eql true
          expect(set.event_conflicts?(:any_state, :reset)).to eql true
        end
      end
    end

    describe 'with direct and :any_state transitions set' do
      before do
        set.add(:a, :b, config1)
        set.add(:b, :c, config2)
        set.add(:any_state, :d, config3, :done)
        set.add(:any_state, :e, config4)
      end

      context '#get_by_end_state' do
        it 'returns nil if the configuration does not exist' do
          expect(set.get_by_end_state(:d, :a)).to be_nil
          expect(set.get_by_end_state(:d, :b)).to be_nil
        end

        it 'returns the configuration if it exists' do
          expect(set.get_by_end_state(:a, :d)).to eql config3
          expect(set.get_by_end_state(:b, :d)).to eql config3
          expect(set.get_by_end_state(:c, :d)).to eql config3
          expect(set.get_by_end_state(:d, :d)).to eql config3
          expect(set.get_by_end_state(:e, :d)).to eql config3

          expect(set.get_by_end_state(:a, :e)).to eql config4
          expect(set.get_by_end_state(:b, :e)).to eql config4
          expect(set.get_by_end_state(:c, :e)).to eql config4
          expect(set.get_by_end_state(:d, :e)).to eql config4
          expect(set.get_by_end_state(:e, :e)).to eql config4
        end
      end

      context '#get_by_event' do
        it 'returns nil if the end_state does not exist' do
          expect(set.get_by_event(:a, :invalid)).to be_nil
          expect(set.get_by_event(:e, :go)).to be_nil
        end

        it 'returns the end state if it exists' do
          expect(set.get_by_event(:a, :done)).to eql :d
          expect(set.get_by_event(:b, :done)).to eql :d
          expect(set.get_by_event(:c, :done)).to eql :d
          expect(set.get_by_event(:d, :done)).to eql :d
          expect(set.get_by_event(:e, :done)).to eql :d
        end
      end

      context '#each' do
        it 'iterates over all transitions' do
          expect{ |b| set.each(&b) }.to yield_control.exactly(12)
          expect(set.each).to match_array [
            [:a, :b, config1, nil], [:b, :c, config2, nil],
            [:a, :d, config3, :done], [:b, :d, config3, :done], [:c, :d, config3, :done], [:d, :d, config3, :done], [:e, :d, config3, :done],
            [:a, :e, config4, nil], [:b, :e, config4, nil], [:c, :e, config4, nil], [:d, :e, config4, nil], [:e, :e, config4, nil]
          ]
        end
      end

      context '#start_states' do
        it 'returns all the start_states' do
          expect(set.start_states).to match_array [:a, :b, :c, :d, :e]
        end
      end

      context '#end_states' do
        it 'returns all the end_states' do
          expect(set.end_states).to match_array [:b, :c, :d, :e]
        end
      end

      context '#events' do
        it 'returns all the events' do
          expect(set.events).to match_array [:done]
        end
      end

      context "#event_conflicts?" do
        it 'returns false if the event would not conflict with an existing event' do
          expect(set.event_conflicts?(:a, :other)).to eql false
          expect(set.event_conflicts?(:b, :other)).to eql false
          expect(set.event_conflicts?(:c, :other)).to eql false
          expect(set.event_conflicts?(:any_state, :other)).to eql false
        end

        it 'returns true if the event would conflict with an existing event' do
          expect(set.event_conflicts?(:a, :done)).to eql true
          expect(set.event_conflicts?(:b, :done)).to eql true
          expect(set.event_conflicts?(:c, :done)).to eql true
          expect(set.event_conflicts?(:d, :done)).to eql true
          expect(set.event_conflicts?(:e, :done)).to eql true
        end
      end
    end
  end
end
