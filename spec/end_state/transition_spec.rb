require 'spec_helper'
require 'ostruct'

module EndState
  describe Transition do
    subject(:transition) { Transition.new(object, previous_state, state, configuration, mode) }
    let(:object) { double :object, failure_messages: [] }
    let(:previous_state) { :a }
    let(:state) { :b }
    let(:configuration) { OpenStruct.new(action: action, concluders: [], guards: [], required_params: []) }
    let(:action) { double :action, new: action_instance }
    let(:action_instance) { double :action_instance, call: action_return_value, rollback: nil }
    let(:action_return_value) { true }
    let(:mode) { :soft }

    describe '#allowed?' do
      let(:guard) { double :guard, new: guard_instance }
      let(:guard_instance) { double :guard_instance, allowed?: nil }
      before { configuration.guards << guard }

      context 'when all guards pass' do
        before { allow(guard_instance).to receive(:allowed?).and_return(true) }

        specify { expect(transition.allowed?).to be true }

        context 'when params are provided' do
          it 'creates the guard with the params' do
            transition.allowed?({ foo: 'bar' })
            expect(guard).to have_received(:new).with(object, state, { foo: 'bar' })
          end

          context 'and some params are required' do
            before { configuration.required_params = [:foo, :bar] }

            context 'and not all required are provided' do
              it 'raises MissingParams' do
                expect { transition.allowed? foo: 'something' }.to raise_error(MissingParams, 'Missing params: bar')
              end
            end

            context 'and all required are provided' do
              specify { expect(transition.allowed? foo: 1, bar: 2).to be true }
            end
          end
        end
      end

      context 'when not all guards pass' do
        before { allow(guard_instance).to receive(:allowed?).and_return(false) }

        specify { expect(transition.allowed?).to be false }
      end
    end

    describe '#will_allow?' do
      let(:guard) { double :guard, new: guard_instance }
      let(:guard_instance) { double :guard_instance, will_allow?: nil }
      before { configuration.guards << guard }

      context 'when all guards pass' do
        before { allow(guard_instance).to receive(:will_allow?).and_return(true) }

        specify { expect(transition.will_allow?).to be true }

        context 'when params are provided' do
          it 'creates the guard with the params' do
            transition.will_allow?({ foo: 'bar' })
            expect(guard).to have_received(:new).with(object, state, { foo: 'bar' })
          end

          context 'and some params are required' do
            before { configuration.required_params = [:foo, :bar] }

            context 'and not all required are provided' do
              specify { expect(transition.will_allow?).to be false }
            end

            context 'and all required are provided' do
              specify { expect(transition.will_allow? foo: 1, bar: 2).to be true }
            end
          end
        end
      end

      context 'when not all guards pass' do
        before { allow(guard_instance).to receive(:will_allow?).and_return(false) }

        specify { expect(transition.will_allow?).to be false }
      end

      context 'when params are provided' do
        it 'creates the guard with the params' do
          transition.will_allow?({ foo: 'bar' })
          expect(guard).to have_received(:new).with(object, state, { foo: 'bar' })
        end
      end
    end

    describe '#call' do
      context 'when a guard returns false' do
        let(:guard) { double :guard, new: guard_instance }
        let(:guard_instance) { double :guard_instance, allowed?: false }
        before do
          configuration.guards << guard
          object.failure_messages << 'not ready'
        end

        context 'soft mode' do
          let(:mode) { :soft }

          it 'returns false' do
            expect(transition.call).to be false
          end
        end

        context 'hard mode' do
          let(:mode) { :hard }

          it 'raises GuardFailed' do
            expect{transition.call}.to raise_error(GuardFailed, 'The transition to b was blocked: not ready')
          end
        end
      end

      context 'when action returns false' do
        let(:action_return_value) { false }

        it 'returns false' do
          expect(transition.call).to be false
        end
      end

      context 'when a concluder returns false' do
        let(:concluder1) { double :concluder, new: concluder1_instance }
        let(:concluder1_instance) { double :concluder_instance, call: true, rollback: nil }
        let(:concluder2) { double :concluder, new: concluder2_instance }
        let(:concluder2_instance) { double :concluder_instance, call: false, rollback: nil }
        let(:concluder3) { double :concluder, new: concluder3_instance }
        let(:concluder3_instance) { double :concluder_instance, call: true, rollback: nil }
        before do
          configuration.concluders = [concluder1, concluder2, concluder3]
          object.failure_messages << 'service failure'
        end

        context 'soft mode' do
          let(:mode) { :soft }

          it 'returns false and rolls back the completed concluders and the action' do
            expect(action_instance).to receive(:rollback).ordered
            expect(concluder3_instance).to_not receive(:rollback)
            expect(concluder2_instance).to receive(:rollback).ordered
            expect(concluder1_instance).to receive(:rollback).ordered

            expect(transition.call).to be false
          end
        end

        context 'hard mode' do
          let(:mode) { :hard }

          it 'raises ConcluderFailed and rolls back the completed concluders and the action' do
            expect(action_instance).to receive(:rollback).ordered
            expect(concluder3_instance).to_not receive(:rollback)
            expect(concluder2_instance).to receive(:rollback).ordered
            expect(concluder1_instance).to receive(:rollback).ordered

            expect{transition.call}.to raise_error(ConcluderFailed, 'The transition to b was rolled back: service failure')
          end
        end
      end

      context 'when guards, action, and concluders return true' do
        it 'returns true' do
          expect(transition.call).to be true
        end
      end
    end
  end
end
