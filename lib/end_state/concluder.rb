module EndState
  class Concluder
    include Messages
    attr_reader :object, :state, :params

    def initialize(object, state, params)
      @object = object
      @state = state
      @params = params
    end

    def call
      false
    end

    def rollback
      true
    end
  end
end
