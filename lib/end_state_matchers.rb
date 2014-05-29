module EndStateMatchers
  def have_transition(transition)
    TransitionMatcher.new(transition)
  end

  class TransitionMatcher
    attr_reader :transition, :machine, :failure_messages, :guards, :finalizers

    def initialize(transition)
      @transition = transition
      @failure_messages = []
      @guards = []
      @finalizers = []
    end

    def matches?(actual)
      @machine = actual
      verify
    end

    def failure_message
      failure_messages.join("\n")
    end

    def description
      "have transition :#{transition.keys.first} => :#{transition.values.first}"
    end

    def with_guard(guard)
      @guards << guard
      self
    end

    def with_guards(*guards)
      @guards += Array(guards)
      self
    end

    def with_finalizer(finalizer)
      @finalizers << finalizer
      self
    end

    def with_finalizers(*finalizers)
      @finalizers += Array(finalizers)
      self
    end

    private

    def verify
      result = true
      if machine.transitions.keys.include? transition
        result = (result && verify_guards) if guards.any?
        result = (result && verify_finalizers) if finalizers.any?
        result
      else
        failure_messages << "expected that #{machine.name} would have transition :#{transition.keys.first} => :#{transition.values.first}"
        false
      end
    end

    def verify_guards
      result = true
      guards.each do |guard|
        unless machine.transitions[transition].guards.any? { |g| g == guard }
          failure_messages << "expected that transition :#{transition.keys.first} => :#{transition.values.first} would have guard #{guard.name}"
          result = false
        end
      end
      result
    end

    def verify_finalizers
      result = true
      finalizers.each do |finalizer|
        unless machine.transitions[transition].finalizers.any? { |f| f == finalizer }
          failure_messages << "expected that transition :#{transition.keys.first} => :#{transition.values.first} would have finalizer #{finalizer.name}"
          result = false
        end
      end
      result
    end
  end
end

include EndStateMatchers
