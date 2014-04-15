require 'spec_helper'

module EndState
  module Finalizers
    describe Persistence do
      subject(:finalizer) { Persistence.new(object, state, params) }
      let(:object) { double :object, save: nil }
      let(:state) { :b }
      let(:params) { {} }

      describe '#call' do
        it 'calls save on the object' do
          finalizer.call
          expect(object).to have_received(:save)
        end

        context 'when the object does not respond to save' do
          let(:object) { Object.new }

          it 'returns false' do
            expect(finalizer.call).to be_false
          end
        end
      end

      describe '#rollback' do
        it 'calls save on the object' do
          finalizer.rollback
          expect(object).to have_received(:save)
        end

        context 'when the object does not respond to save' do
          let(:object) { Object.new }

          it 'returns true' do
            expect(finalizer.rollback).to be_true
          end
        end
      end
    end
  end
end
