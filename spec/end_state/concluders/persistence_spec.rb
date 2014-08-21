require 'spec_helper'

module EndState
  module Concluders
    describe Persistence do
      subject(:concluder) { Persistence.new(object, state, params) }
      let(:object) { double :object, save: nil }
      let(:state) { :b }
      let(:params) { {} }

      describe '#call' do
        it 'calls save on the object' do
          concluder.call
          expect(object).to have_received(:save)
        end

        context 'when the object does not respond to save' do
          let(:object) { Object.new }

          it 'returns false' do
            expect(concluder.call).to be false
          end
        end
      end

      describe '#rollback' do
        it 'calls save on the object' do
          concluder.rollback
          expect(object).to have_received(:save)
        end

        context 'when the object does not respond to save' do
          let(:object) { Object.new }

          it 'returns true' do
            expect(concluder.rollback).to be true
          end
        end
      end
    end
  end
end
