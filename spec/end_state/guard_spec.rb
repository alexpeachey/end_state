require 'spec_helper'

module EndState
  describe Guard do
    subject(:guard) { Guard.new(object, state, params) }
    let(:object) { Struct.new('Machine', :failure_messages, :success_messages, :state, :store_states_as_strings).new }
    let(:state) { :a }
    let(:params) { {} }
    before do
      object.failure_messages = []
      object.success_messages = []
    end

    describe '#add_error' do
      it 'adds an error' do
        guard.add_error('error')
        expect(object.failure_messages).to eq ['error']
      end
    end

    describe '#add_success' do
      it 'adds an success' do
        guard.add_success('success')
        expect(object.success_messages).to eq ['success']
      end
    end

    describe 'will_allow?' do
      it 'returns false' do
        expect(guard.will_allow?).to be false
      end
    end

    describe 'allowed?' do
      context 'will_allow? returns true' do
        before { allow(guard).to receive(:will_allow?).and_return(true) }

        it 'calls passed and returns true' do
          expect(guard).to receive(:passed)
          expect(guard.allowed?).to be true
        end
      end

      context 'will_allow? returns false' do
        before { allow(guard).to receive(:will_allow?).and_return(false) }

        it 'calls failed and returns false' do
          expect(guard).to receive(:failed)
          expect(guard.allowed?).to be false
        end
      end
    end
  end
end
