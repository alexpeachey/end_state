module EndState
  class Transition
    attr_reader :state, :blocked_event_message
    attr_accessor :action, :guards, :concluders

    def initialize(state)
      @state = state
      @action = Action
      @guards = []
      @concluders = []
    end

    def allowed?(object, params={})
      guards.all? { |guard| guard.new(object, state, params).allowed? }
    end

    def will_allow?(object, params={})
      guards.all? { |guard| guard.new(object, state, params).will_allow? }
    end

    def conclude(object, previous_state, params={})
      concluders.each_with_object([]) do |concluder, concluded|
        concluded << concluder
        return rollback(concluded, object, previous_state, params) unless run_concluder(concluder, object, state, params)
      end
      true
    end

    def custom_action(action)
      @action = action
    end

    def guard(guard)
      guards << guard
    end

    def concluder(concluder)
      concluders << concluder
    end

    def persistence_on
      concluder Concluders::Persistence
    end

    def blocked(message)
      @blocked_event_message = message
    end

    # Backward compatibility
    # Finalizer is deprecated
    alias_method :finalizers, :concluders
    alias_method :finalize, :conclude
    alias_method :finalizer, :concluder

    private

    def rollback(concluded, object, previous_state, params)
      action.new(object, previous_state).rollback
      concluded.reverse.each { |concluder| concluder.new(object, state, params).rollback }
      false
    end

    def run_concluder(concluder, object, state, params)
      concluder.new(object, state, params).call
    end
  end
end
