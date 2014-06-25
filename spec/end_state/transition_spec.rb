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
      let(:another_guard) { double :another_guard }

      it 'adds a guard' do
        expect { transition.guard guard }.to change(transition.guards, :count).by(1)
      end

      it 'adds multiple guards' do
        expect { transition.guard guard, another_guard }.to change(transition.guards, :count).by(2)
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

    describe '#concluder' do
      let(:concluder) { double :concluder }
      let(:another_concluder) { double :another_concluder }

      it 'adds a concluder' do
        expect { transition.concluder concluder }.to change(transition.concluders, :count).by(1)
      end

      it 'adds multiple concluders' do
        expect { transition.concluder concluder, another_concluder }.to change(transition.concluders, :count).by(2)
      end
    end

    describe '#persistence_on' do
      it 'adds a Persistence concluder' do
        expect { transition.persistence_on }.to change(transition.concluders, :count).by(1)
      end
    end

    describe '#conclude' do
      let(:concluder) { double :concluder, new: concluder_instance }
      let(:concluder_instance) { double :concluder_instance, call: nil, rollback: nil }
      let(:object) { OpenStruct.new(state: :b) }
      before do
        object.stub_chain(:class, :store_states_as_strings).and_return(false)
        transition.concluders << concluder
      end

      context 'when all concluders succeed' do
        before { concluder_instance.stub(:call).and_return(true) }

        specify { expect(transition.conclude object, :a).to be_true }
      end

      context 'when not all concluders succeed' do
        before { concluder_instance.stub(:call).and_return(false) }

        specify { expect(transition.conclude object, :a).to be_false }

        it 'rolls them back' do
          transition.conclude object, :a
          expect(concluder_instance).to have_received(:rollback)
        end
      end

      context 'when params are provided' do
        it 'creates a concluder with the params' do
          transition.conclude object, :b, { foo: 'bar' }
          expect(concluder).to have_received(:new).twice.with(object, :a, { foo: 'bar'} )
        end
      end
    end
  end
end
