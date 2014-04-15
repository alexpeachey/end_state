require 'spec_helper'

module EndState
  module Guards
    describe AllowPreviousStates do
      subject(:guard) { AllowPreviousStates.new(object, state, params) }
      let(:object) { OpenStruct.new(state: :a) }
      let(:state) { :b }
      let(:params) { { states: allowed_states } }

      context 'when the object state is in the allowed_states' do
        let(:allowed_states) { [:a] }

        it 'returns true' do
          expect(guard.call).to be_true
        end
      end

      context 'when the object state is not in the allowed_states' do
        let(:allowed_states) { [] }

        it 'returns true' do
          expect(guard.call).to be_false
        end
      end
    end
  end
end
