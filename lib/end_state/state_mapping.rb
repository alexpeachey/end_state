module EndState
  class StateMapping < Hash
    def start_state
      keys.first
    end

    def end_state
      values.first
    end

    def any_start_state?
      start_state == :any_state
    end

    def matches_start_state?(state)
      start_state == state || any_start_state?
    end

    def conflicts?(state_mapping)
      start_state == state_mapping.start_state ||
      any_start_state? ||
      state_mapping.any_start_state?
    end

    def to_s
      "#{start_state} => #{end_state}"
    end
  end
end
