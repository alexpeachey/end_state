module EndState
  class Error < StandardError; end
  class UnknownState < Error; end
  class InvalidTransition < Error; end
  class GuardFailed < Error; end
  class ConcluderFailed < Error; end
end
