module EndState
  class Transition
    attr_reader :state
    attr_accessor :action, :guards, :finalizers

    def initialize(state)
      @state = state
      @action = Action
      @guards = []
      @finalizers = []
    end

    def allowed?(object)
      guards.all? { |guard| guard[:guard].new(object, state, guard[:params]).allowed? }
    end

    def will_allow?(object)
      guards.all? { |guard| guard[:guard].new(object, state, guard[:params]).will_allow? }
    end

    def finalize(object, previous_state)
      finalizers.each_with_object([]) do |finalizer, finalized|
        finalized << finalizer
        return rollback(finalized, object, previous_state) unless run_finalizer(finalizer, object, state)
      end
      true
    end

    def custom_action(action)
      @action = action
    end

    def guard(guard, params = {})
      guards << { guard: guard, params: params }
    end

    def finalizer(finalizer, params = {})
      finalizers << { finalizer: finalizer, params: params }
    end

    def persistence_on
      finalizer Finalizers::Persistence
    end

    private

    def rollback(finalized, object, previous_state)
      action.new(object, previous_state).rollback
      finalized.reverse.each { |f| f[:finalizer].new(object, state, f[:params]).rollback }
      false
    end

    def run_finalizer(finalizer, object, state)
      finalizer[:finalizer].new(object, state, finalizer[:params]).call
    end
  end
end
