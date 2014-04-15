module EndState
  module Guards
    class DenyPreviousStates < Guard
      def call
        return false if Array(params[:states]).include? object.state
        true
      end
    end
  end
end
