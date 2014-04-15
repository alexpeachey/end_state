require 'spec_helper'
require 'ostruct'

module EndState
  describe StateMachine do
    subject(:machine) { StateMachine.new(object) }
    let(:object) { OpenStruct.new(state: nil) }
    before { StateMachine.instance_variable_set '@transitions'.to_sym, nil }

    describe '.transition' do
      let(:state) { :a }
      let(:yielded) { OpenStruct.new(transition: nil) }
      before { StateMachine.transition(state) { |transition| yielded.transition = transition } }

      it 'yields a transition for the supplied state' do
        expect(yielded.transition.state).to eq state
      end

      it 'does not require a block' do
        expect(StateMachine.transition(:b)).not_to raise_error
      end

      it 'adds the transition to the state machine' do
        expect(StateMachine.transitions[state]).to eq yielded.transition
      end
    end

    describe '#state' do
      context 'when the object has state :a' do
        let(:object) { OpenStruct.new(state: :a) }

        specify { expect(machine.state).to eq :a }
      end

      context 'when the object has state :b' do
        let(:object) { OpenStruct.new(state: :b) }

        specify { expect(machine.state).to eq :b }
      end
    end

    describe '#{state}?' do
      before do
        StateMachine.transition :a
        StateMachine.transition :b
      end

      context 'when the object has state :a' do
        let(:object) { OpenStruct.new(state: :a) }

        specify { expect(machine.a?).to be_true }
        specify { expect(machine.b?).to be_false }
      end

      context 'when the object has state :b' do
        let(:object) { OpenStruct.new(state: :b) }

        specify { expect(machine.b?).to be_true }
        specify { expect(machine.a?).to be_false }
      end
    end

    describe '#transition' do
      context 'when the transition does not exist' do
        it 'raises an unknown state error' do
          expect { machine.transition(:no_state) }.to raise_error(UnknownState)
        end
      end

      context 'when the transition does exist' do
        context 'and no configuration is given' do
          before { StateMachine.transition :a }

          it 'transitions the state' do
            machine.transition :a
            expect(object.state).to eq :a
          end
        end

        context 'and a guard is configured' do
          before do
            StateMachine.transition :b do |transition|
              transition.allow_previous_states :a
            end
          end

          context 'and the object satisfies the guard' do
            before { object.state = :a }

            it 'transitions the state' do
              machine.transition :b
              expect(object.state).to eq :b
            end
          end

          context 'and the object does not satisfy the guard' do
            before { object.state = :c }

            it 'does not transition the state' do
              machine.transition :b
              expect(object.state).to eq :c
            end
          end
        end

        context 'and a finalizer is configured' do
          before do
            StateMachine.transition :b do |transition|
              transition.persistence_on
            end
          end

          context 'and the finalizer is successful' do
            before do
              object.state = :a
              object.stub(:save).and_return(true)
            end

            it 'transitions the state' do
              machine.transition :b
              expect(object.state).to eq :b
            end
          end

          context 'and the finalizer fails' do
            before do
              object.state = :a
              object.stub(:save).and_return(false)
            end

            it 'does not transition the state' do
              machine.transition :b
              expect(object.state).to eq :a
            end
          end
        end
      end
    end
  end
end
