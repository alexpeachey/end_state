module EndState
  module Guards
    class AllowPreviousStates < Guard
      def call
        return false unless Array(params[:states]).include? object.state
        true
      end
    end
  end
end
