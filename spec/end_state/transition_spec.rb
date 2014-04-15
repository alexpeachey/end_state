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

    describe '#guard' do
      let(:guard) { double :guard }

      it 'adds a guard' do
        expect { transition.guard guard }.to change(transition.guards, :count).by(1)
      end

      context 'when params are provided' do
        let(:params) { {} }

        it 'adds a guard' do
          expect { transition.guard guard, params }.to change(transition.guards, :count).by(1)
        end
      end
    end

    describe '#allow_previous_states' do
      it 'adds an AllowPreviousStates guard for the provided states' do
        expect { transition.allow_previous_states :a }.to change(transition.guards, :count).by(1)
      end
    end

    describe '#deny_previous_states' do
      it 'adds an DenyPreviousStates guard for the provided states' do
        expect { transition.deny_previous_states :a }.to change(transition.guards, :count).by(1)
      end
    end

    describe '#guards_pass?' do
      let(:guard) { double :guard, new: guard_instance }
      let(:guard_instance) { double :guard_instance, call: nil }
      before { transition.guards << { guard: guard, params: {} } }

      context 'when all guards pass' do
        let(:object) { double :object }
        before { guard_instance.stub(:call).and_return(true) }

        specify { expect(transition.guards_pass? object).to be_true }
      end

      context 'when not all guards pass' do
        let(:object) { double :object }
        before { guard_instance.stub(:call).and_return(false) }

        specify { expect(transition.guards_pass? object).to be_false }
      end
    end

    describe '#finalizer' do
      let(:finalizer) { double :finalizer }

      it 'adds a finalizer' do
        expect { transition.finalizer finalizer }.to change(transition.finalizers, :count).by(1)
      end

      context 'when params are provided' do
        let(:params) { {} }

        it 'adds a finalizer' do
          expect { transition.finalizer finalizer, params }.to change(transition.finalizers, :count).by(1)
        end
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
      before { transition.finalizers << { finalizer: finalizer, params: {} } }

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
    end
  end
end
