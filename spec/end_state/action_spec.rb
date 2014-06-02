require 'spec_helper'

module EndState
  describe Action do
    subject(:action) { Action.new(object, state) }
    let(:object) { OpenStruct.new(state: nil) }
    let(:state) { :a }

    before { object.stub_chain(:class, :store_states_as_strings).and_return(false) }

    describe '#call' do
      it 'changes the state to the new state' do
        action.call
        expect(object.state).to eq :a
      end
    end

    describe '#rollback' do
      it 'changes the state to the new state' do
        action.rollback
        expect(object.state).to eq :a
      end
    end
  end
end