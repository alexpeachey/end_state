require 'spec_helper'
require 'ostruct'

module EndState
  describe Transition do
    subject(:transition) { Transition.new(state) }
    let(:state) { :a }

    describe '#custom_action' do
      let(:custom) { double :custom }

      it 'sets the action' do
        transition.custom_action custom
        expect(transition.action).to eq custom
      end
    end

    describe '#blocked' do
      it 'sets the blocked event message' do
        transition.blocked 'This is blocked.'
        expect(transition.blocked_event_message).to eq 'This is blocked.'
      end
    end

    describe '#guard' do
      let(:guard) { double :guard }

      it 'adds a guard' do
        expect { transition.guard guard }.to change(transition.guards, :count).by(1)
      end
    end

    describe '#allowed?' do
      let(:guard) { double :guard, new: guard_instance }
      let(:guard_instance) { double :guard_instance, allowed?: nil }
      let(:object) { double :object }
      before { transition.guards << guard }

      context 'when all guards pass' do
        before { guard_instance.stub(:allowed?).and_return(true) }

        specify { expect(transition.allowed? object).to be_true }
      end

      context 'when not all guards pass' do
        before { guard_instance.stub(:allowed?).and_return(false) }

        specify { expect(transition.allowed? object).to be_false }
      end

      context 'when params are provided' do
        it 'creates the guard with the params' do
          transition.allowed? object, { foo: 'bar' }
          expect(guard).to have_received(:new).with(object, state, { foo: 'bar' })
        end
      end
    end

    describe '#will_allow?' do
      let(:guard) { double :guard, new: guard_instance }
      let(:guard_instance) { double :guard_instance, will_allow?: nil }
      let(:object) { double :object }
      before { transition.guards << guard }

      context 'when all guards pass' do
        before { guard_instance.stub(:will_allow?).and_return(true) }

        specify { expect(transition.will_allow? object).to be_true }
      end

      context 'when not all guards pass' do
        before { guard_instance.stub(:will_allow?).and_return(false) }

        specify { expect(transition.will_allow? object).to be_false }
      end

      context 'when params are provided' do
        it 'creates the guard with the params' do
          transition.will_allow? object, { foo: 'bar' }
          expect(guard).to have_received(:new).with(object, state, { foo: 'bar' })
        end
      end
    end

    describe '#finalizer' do
      let(:finalizer) { double :finalizer }

      it 'adds a finalizer' do
        expect { transition.finalizer finalizer }.to change(transition.finalizers, :count).by(1)
      end
    end

    describe '#persistence_on' do
      it 'adds a Persistence finalizer' do
        expect { transition.persistence_on }.to change(transition.finalizers, :count).by(1)
      end
    end

    describe '#finalize' do
      let(:finalizer) { double :finalizer, new: finalizer_instance }
      let(:finalizer_instance) { double :finalizer_instance, call: nil, rollback: nil }
      let(:object) { OpenStruct.new(state: :b) }
      before do
        object.stub_chain(:class, :store_states_as_strings).and_return(false)
        transition.finalizers << finalizer
      end

      context 'when all finalizers succeed' do
        before { finalizer_instance.stub(:call).and_return(true) }

        specify { expect(transition.finalize object, :a).to be_true }
      end

      context 'when not all finalizers succeed' do
        before { finalizer_instance.stub(:call).and_return(false) }

        specify { expect(transition.finalize object, :a).to be_false }

        it 'rolls them back' do
          transition.finalize object, :a
          expect(finalizer_instance).to have_received(:rollback)
        end
      end

      context 'when params are provided' do
        it 'creates a finalizer with the params' do
          transition.finalize object, :b, { foo: 'bar' }
          expect(finalizer).to have_received(:new).twice.with(object, :a, { foo: 'bar'} )
        end
      end
    end
  end
end
