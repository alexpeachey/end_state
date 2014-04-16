module EndState
  module Finalizers
    class Persistence < EndState::Finalizer
      def call
        return false unless object.respond_to? :save
        !!(object.save)
      end

      def rollback
        return true unless object.respond_to? :save
        !!(object.save)
      end
    end
  end
end
