require 'spec_helper'
require 'ostruct'

module EndState
  describe StateMachineConfiguration do
    subject(:machine) { StateMachine.new(object) }
    let(:object) { OpenStruct.new(state: nil) }
    before do
      StateMachine.instance_variable_set '@transition_configurations'.to_sym, nil
      StateMachine.instance_variable_set '@events'.to_sym, nil
      StateMachine.instance_variable_set '@store_states_as_strings'.to_sym, nil
      StateMachine.instance_variable_set '@initial_state'.to_sym, :__nil__
      StateMachine.instance_variable_set '@mode'.to_sym, :soft
    end

    describe '.transition' do
      let(:options) { { a: :b } }

      before do
        @transition_configuration = nil
        StateMachine.transition(options) { |tc| @transition_configuration = tc }
      end

      it 'does not require a block' do
        expect { StateMachine.transition(options) }.not_to raise_error
      end

      context 'single transition' do
        it 'yields a transition configuraton' do
          expect(@transition_configuration).to be_a TransitionConfiguration
        end

        context 'with as' do
          let(:options) { { a: :b, as: :go } }

          it 'creates an alias' do
            expect(StateMachine).to have_transition(a: :b).with_event(:go)
          end

          context 'another single transition with as' do
            before { StateMachine.transition({c: :d, as: :go}) }

            it 'appends to the event' do
              expect(StateMachine).to have_transition(a: :b).with_event(:go)
              expect(StateMachine).to have_transition(c: :d).with_event(:go)
            end
          end

          context 'another single transition with as that conflicts' do
            it 'raises an error' do
              expect{ StateMachine.transition({a: :c, as: :go}) }.to raise_error EventConflict,
                "Attempting to define event 'go' on state 'a', but it is already defined. " \
                "(Check duplicates and use of 'any_state')"
            end
          end

          context 'another single transition with as that conflicts' do
            it 'raises an error' do
              expect{ StateMachine.transition({any_state: :c, as: :go}) }.to raise_error EventConflict,
                "Attempting to define event 'go' on state 'any_state', but it is already defined. " \
                "(Check duplicates and use of 'any_state')"
            end
          end
        end
      end

      context 'multiple start states' do
        let(:options) { { [:a, :b] => :c } }

        it 'yields a transition configuraton' do
          expect(@transition_configuration).to be_a TransitionConfiguration
        end

        it 'has both transitions' do
          expect(StateMachine).to have_transition(a: :c)
          expect(StateMachine).to have_transition(b: :c)
        end

        context 'with as' do
          let(:options) { { [:a, :b] => :c, as: :go } }

          it 'creates an alias' do
            expect(StateMachine).to have_transition(a: :c).with_event(:go)
            expect(StateMachine).to have_transition(b: :c).with_event(:go)
          end
        end
      end

      context 'multiple transitions' do
        let(:options) { { a: :b, c: :d } }

        it 'yields a transition configuraton' do
          expect(@transition_configuration).to be_a TransitionConfiguration
        end

        it 'has both transitions' do
          expect(StateMachine).to have_transition(a: :b)
          expect(StateMachine).to have_transition(c: :d)
        end

        context 'with as' do
          let(:options) { { a: :b, c: :d, as: :go } }

          it 'creates an alias' do
            expect(StateMachine).to have_transition(a: :b).with_event(:go)
            expect(StateMachine).to have_transition(c: :d).with_event(:go)
          end
        end
      end
    end

    describe '.state_attribute' do
      context 'when set to :foobar' do
        let(:object) { OpenStruct.new(foobar: :a) }
        before { StateMachine.state_attribute :foobar }

        it 'answers state with foobar' do
          expect(machine.state).to eq object.foobar
        end

        it 'answers state= with foobar=' do
          machine.state = :b
          expect(object.foobar).to eq :b
        end

        after do
          StateMachine.send(:remove_method, :state)
          StateMachine.send(:remove_method, :state=)
        end
      end
    end

    describe '.states' do
      before do
        StateMachine.transition(a: :b)
        StateMachine.transition(b: :c)
      end

      specify { expect(StateMachine.states).to eq [:a, :b, :c] }
    end

    describe '.start_states' do
      before do
        StateMachine.transition(a: :b)
        StateMachine.transition(b: :c)
      end

      specify { expect(StateMachine.start_states).to eq [:a, :b] }
    end

    describe '.end_states' do
      before do
        StateMachine.transition(a: :b)
        StateMachine.transition(b: :c)
      end

      specify { expect(StateMachine.end_states).to eq [:b, :c] }
    end

    describe '.store_states_as_strings!' do
      it 'sets the flag' do
        StateMachine.store_states_as_strings!
        expect(StateMachine.store_states_as_strings).to be true
      end
    end

    describe '.store_states_as_strings' do
      it 'is false by default' do
        expect(StateMachine.store_states_as_strings).to be false
      end
    end

    describe '.initial_state' do
      context 'when set to :first' do
        before { StateMachine.set_initial_state :first }

        it 'has that initial state' do
          expect(machine.state).to eq :first
        end
      end
    end
  end
end
