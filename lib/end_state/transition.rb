module EndState
  class Transition
    attr_reader :configuration, :mode, :object, :previous_state, :state

    def initialize(object, previous_state, state, configuration, mode)
      @object = object
      @previous_state = previous_state
      @state = state
      @configuration = configuration
      @mode = mode
    end

    def call(params={})
      return guard_failed unless allowed?(params)
      return false unless action.new(object, state).call
      return conclude_failed unless conclude(params)
      true
    end

    def allowed?(params={})
      raise "Missing params: #{missing_params(params).join(',')}" unless missing_params(params).empty?
      guards.all? { |guard| guard.new(object, state, params).allowed? }
    end

    def will_allow?(params={})
      return false unless missing_params(params).empty?
      guards.all? { |guard| guard.new(object, state, params).will_allow? }
    end

    private

    def failed(error, message)
      return false unless mode == :hard
      fail error, "The transition to #{state} was #{message}: #{object.failure_messages.join(', ')}"
    end

    def guard_failed
      failed GuardFailed, 'blocked'
    end

    def conclude_failed
      failed ConcluderFailed, 'rolled back'
    end

    def conclude(params={})
      concluders.each_with_object([]) do |concluder, concluded|
        concluded << concluder
        return rollback(concluded, params) unless concluder.new(object, state, params).call
      end
      true
    end

    def rollback(concluded, params)
      concluded.reverse_each { |concluder| concluder.new(object, state, params).rollback }
      action.new(object, previous_state).rollback
      false
    end

    def missing_params(params)
      required_params.select { |key| params[key].nil? }
    end

    [:action, :concluders, :guards, :required_params].each do |method|
      define_method(method) { configuration.public_send(method) }
      private method
    end
  end
end
