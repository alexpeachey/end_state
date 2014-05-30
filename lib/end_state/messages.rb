module EndState
  module Messages
    def add_error(message)
      object.failure_messages << message
    end

    def add_success(message)
      object.success_messages << message
    end
  end
end