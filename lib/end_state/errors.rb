module EndState
  class Error < StandardError; end
  class UnknownState < Error; end
  class UnknownTransition < Error; end
  class InvalidEvent < Error; end
  class GuardFailed < Error; end
  class ConcluderFailed < Error; end

  # Backward compatibility
  # Finalizer is deprecated
  FinalizerFailed = ConcluderFailed
end
