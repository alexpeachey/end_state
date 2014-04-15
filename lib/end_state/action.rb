module EndState
  class Action
    attr_reader :object, :state

    def initialize(object, state)
      @object = object
      @state = state
    end

    def call
      object.state = state
      true
    end

    def rollback
      call
    end
  end
end
