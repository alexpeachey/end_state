module EndState
  class Guard
    attr_reader :object, :state, :params

    def initialize(object, state, params)
      @object = object
      @state = state
      @params = params
    end

    def allowed?
      will_allow?.tap do |result|
        failed unless result
        passed if result
      end
    end

    def will_allow?
      false
    end

    def passed
    end

    def failed
    end
  end
end
