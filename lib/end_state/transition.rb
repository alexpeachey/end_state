module EndState
  class Transition
    attr_reader :state, :blocked_event_message
    attr_accessor :action, :guards, :concluders, :allowed_params, :required_params

    def initialize(state)
      @state = state
      @action = Action
      @guards = []
      @concluders = []
      @allowed_params = []
      @required_params = []
    end

    def allowed?(object, params={})
      raise "Missing params: #{missing_params(params).join(',')}" unless missing_params(params).empty?
      guards.all? { |guard| guard.new(object, state, params).allowed? }
    end

    def will_allow?(object, params={})
      return false unless missing_params(params).empty?
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

    def guard(*guards)
      Array(guards).flatten.each { |guard| self.guards << guard }
    end

    def concluder(*concluders)
      Array(concluders).flatten.each { |concluder| self.concluders << concluder }
    end

    def persistence_on
      concluder Concluders::Persistence
    end

    def allow_params(*params)
      Array(params).flatten.each do |param|
        self.allowed_params << param unless self.allowed_params.include? param
      end
    end

    def require_params(*params)
      Array(params).flatten.each do |param|
        self.allowed_params << param unless self.allowed_params.include? param
        self.required_params << param unless self.required_params.include? param
      end
    end

    def blocked(message)
      @blocked_event_message = message
    end

    private

    def rollback(concluded, object, previous_state, params)
      action.new(object, previous_state).rollback
      concluded.reverse.each { |concluder| concluder.new(object, state, params).rollback }
      false
    end

    def run_concluder(concluder, object, state, params)
      concluder.new(object, state, params).call
    end

    def missing_params(params)
      required_params.select { |key| params[key].nil? }
    end
  end
end
