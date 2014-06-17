module EndState
  module Concluders
    class Persistence < EndState::Concluder
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

  # Backward compatibility
  # Finalizer is deprecated
  Finalizers = Concluders
end
