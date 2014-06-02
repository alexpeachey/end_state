module EndState
  class Transition
    attr_reader :state, :blocked_event_message
    attr_accessor :action, :guards, :finalizers

    def initialize(state)
      @state = state
      @action = Action
      @guards = []
      @finalizers = []
    end

    def allowed?(object, params={})
      guards.all? { |guard| guard.new(object, state, params).allowed? }
    end

    def will_allow?(object, params={})
      guards.all? { |guard| guard.new(object, state, params).will_allow? }
    end

    def finalize(object, previous_state, params={})
      finalizers.each_with_object([]) do |finalizer, finalized|
        finalized << finalizer
        return rollback(finalized, object, previous_state, params) unless run_finalizer(finalizer, object, state, params)
      end
      true
    end

    def custom_action(action)
      @action = action
    end

    def guard(guard)
      guards << guard
    end

    def finalizer(finalizer)
      finalizers << finalizer
    end

    def persistence_on
      finalizer Finalizers::Persistence
    end

    def blocked(message)
      @blocked_event_message = message
    end

    private

    def rollback(finalized, object, previous_state, params)
      action.new(object, previous_state).rollback
      finalized.reverse.each { |finalizer| finalizer.new(object, state, params).rollback }
      false
    end

    def run_finalizer(finalizer, object, state, params)
      finalizer.new(object, state, params).call
    end
  end
end
