module EndState
  Error = Class.new(StandardError)
  UnknownState = Class.new(Error)
  InvalidTransition = Class.new(Error)
  GuardFailed = Class.new(Error)
  ConcluderFailed = Class.new(Error)
  EventConflict = Class.new(Error)
  MissingParams = Class.new(Error)
end
