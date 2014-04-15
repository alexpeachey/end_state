require 'spec_helper'

module EndState
  module Guards
    describe DenyPreviousStates do
      subject(:guard) { DenyPreviousStates.new(object, state, params) }
      let(:object) { OpenStruct.new(state: :a) }
      let(:state) { :b }
      let(:params) { { states: denied_states } }

      context 'when the object state is in the denied_states' do
        let(:denied_states) { [:a] }

        it 'returns true' do
          expect(guard.call).to be_false
        end
      end

      context 'when the object state is not in the denied_states' do
        let(:denied_states) { [] }

        it 'returns true' do
          expect(guard.call).to be_true
        end
      end
    end
  end
end
