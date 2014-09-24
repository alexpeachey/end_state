require "spec_helper"

module EndState
  class TestGuard1 < EndState::Guard; end
  class TestGuard2 < EndState::Guard; end
  class TestGuard3 < EndState::Guard; end

  class TestConcluder1 < EndState::Concluder; end
  class TestConcluder2 < EndState::Concluder; end
  class TestConcluder3 < EndState::Concluder; end

  class TestMachine < EndState::StateMachine
    transition a: :b, as: :go do |t|
      t.guard TestGuard1, TestGuard2
      t.concluder TestConcluder1, TestConcluder2
      t.require_params :a, :b
    end
  end

  describe 'matchers' do
    describe 'have_transition' do
      it 'passes when the transition is present' do
        expect(TestMachine).to have_transition(a: :b)
      end

      it 'has a description' do
        expect(have_transition(a: :b).description).to eq("have transition a => b")
      end

      it 'fails when the guard is not present' do
        expect {
          expect(TestMachine).to have_transition(b: :c)
        }.to fail_with('expected transition b => c to be defined')
      end

      describe 'with_event' do
        it 'passes when the guard is present' do
          expect(TestMachine).to have_transition(a: :b).with_event(:go)
        end

        it 'fails when the guard is not present' do
          expect {
            expect(TestMachine).to have_transition(a: :b).with_event(:reset)
          }.to fail_with('expected transition a => b to have event name: reset')
        end
      end

      describe 'with_guard' do
        it 'passes when the guard is present' do
          expect(TestMachine).to have_transition(a: :b).with_guard(TestGuard1)
        end

        it 'fails when the guard is not present' do
          expect {
            expect(TestMachine).to have_transition(a: :b).with_guard(TestGuard3)
          }.to fail_with('expected transition a => b to have guard EndState::TestGuard3')
        end
      end

      describe 'with_guards' do
        it 'passes when the guards are present' do
          expect(TestMachine).to have_transition(a: :b).with_guards(TestGuard1, TestGuard2)
        end

        it 'fails when the guards are not present' do
          expect {
            expect(TestMachine).to have_transition(a: :b).with_guards(TestGuard2, TestGuard3)
          }.to fail_with('expected transition a => b to have guard EndState::TestGuard3')
        end
      end

      describe 'with_concluder' do
        it 'passes when the concluder is present' do
          expect(TestMachine).to have_transition(a: :b).with_concluder(TestConcluder1)
        end

        it 'fails when the concluder is not present' do
          expect {
            expect(TestMachine).to have_transition(a: :b).with_concluder(TestConcluder3)
          }.to fail_with('expected transition a => b to have concluder EndState::TestConcluder3')
        end
      end

      describe 'with_concluders' do
        it 'passes when the concluders are present' do
          expect(TestMachine).to have_transition(a: :b).with_concluders(TestConcluder1, TestConcluder2)
        end

        it 'fails when the concluders are not present' do
          expect {
            expect(TestMachine).to have_transition(a: :b).with_concluders(TestConcluder2, TestConcluder3)
          }.to fail_with('expected transition a => b to have concluder EndState::TestConcluder3')
        end
      end

      describe 'with_required_params' do
        it 'passes when the required_params match' do
          expect(TestMachine).to have_transition(a: :b).with_required_params(:a, :b)
        end

        it 'fails when the required_params do not match' do
          expect {
            expect(TestMachine).to have_transition(a: :b).with_required_params(:b, :c)
          }.to fail_with('expected transition a => b to have required param c')
        end
      end
    end
  end
end
