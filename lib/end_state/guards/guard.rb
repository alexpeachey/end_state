module EndState
  module Guards
    class Guard
      attr_reader :object, :state, :params

      def initialize(object, state, params)
        @object = object
        @state = state
        @params = params
      end

      def call
        false
      end
    end
  end
end
