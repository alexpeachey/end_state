module EndState
  class Error < StandardError; end
  class UnknownState < Error; end
  class UnknownTransition < Error; end
  class GuardFailed < Error; end
  class FinalizerFailed < Error; end
end
