require 'spec_helper'
require 'ostruct'

module EndState
  describe StateMapping do
    describe 'simple example' do
      let(:subject) { StateMapping[a: :b] }

      context '#start_state' do
        it 'returns the first key' do
          expect(subject.start_state).to eq :a
        end
      end

      context '#end_state' do
        it 'returns the first value' do
          expect(subject.end_state).to eq :b
        end
      end

      context '#any_start_state?' do
        context 'start_state is :any_state' do
          let(:subject) { StateMapping[any_state: :b] }
          it 'returns true' do
            expect(subject.any_start_state?).to eq true
          end
        end

        context 'start_state is anything else' do
          it 'returns false' do
            expect(subject.any_start_state?).to eq false
          end
        end
      end

      context '#matches_start_state?' do
        context 'same start_state' do
          it 'returns true' do
            expect(subject.matches_start_state?(:a)).to eq true
          end
        end

        context 'different start_state' do
          it 'returns false' do
            expect(subject.matches_start_state?(:b)).to eq false
          end
        end

        context 'object has a start_state of :any_state' do
          let(:subject) { StateMapping[any_state: :c] }

          it 'returns true' do
            expect(subject.matches_start_state?(:b)).to eq true
          end
        end
      end

      context '#conflicts?' do
        context 'same start_state' do
          let(:other) { StateMapping[a: :c] }

          it 'returns true' do
            expect(subject.conflicts?(other)).to eq true
          end
        end

        context 'different start_state' do
          let(:other) { StateMapping[c: :d] }

          it 'returns false' do
            expect(subject.conflicts?(other)).to eq false
          end
        end

        context 'argument has a start_state of :any_state' do
          let(:other) { StateMapping[any_state: :c] }

          it 'returns true' do
            expect(subject.conflicts?(other)).to eq true
          end
        end

        context 'object has a start_state of :any_state' do
          let(:subject) { StateMapping[any_state: :c] }
          let(:other) { StateMapping[a: :c] }

          it 'returns true' do
            expect(subject.conflicts?(other)).to eq true
          end
        end
      end
    end
  end
end
