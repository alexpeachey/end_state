module EndStateMatchers
  def have_transition(transition)
    TransitionMatcher.new(transition)
  end

  class TransitionMatcher
    attr_reader :transition, :machine, :failure_messages, :guards, :concluders

    def initialize(transition)
      @transition = transition
      @failure_messages = []
      @guards = []
      @concluders = []
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

    def with_concluder(concluder)
      @concluders << concluder
      self
    end

    def with_concluders(*concluders)
      @concluders += Array(concluders)
      self
    end

    # Backward compatibility
    # Finalizer is deprecated
    alias_method :with_finalizer, :with_concluder
    alias_method :with_finalizers, :with_concluders
    alias_method :finalizers, :concluders

    private

    def verify
      result = true
      if machine.transitions.keys.include? transition
        result = (result && verify_guards) if guards.any?
        result = (result && verify_concluders) if concluders.any?
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

    def verify_concluders
      result = true
      concluders.each do |concluder|
        unless machine.transitions[transition].concluders.any? { |f| f == concluder }
          failure_messages << "expected that transition :#{transition.keys.first} => :#{transition.values.first} would have concluder #{concluder.name}"
          result = false
        end
      end
      result
    end
  end
end

include EndStateMatchers
