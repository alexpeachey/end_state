require 'end_state/state_mapping'

module EndStateMatchers
  def have_transition(transition)
    TransitionMatcher.new(transition)
  end

  class TransitionMatcher
    attr_reader :transition, :machine, :failure_messages, :guards, :concluders, :required_params

    def initialize(transition)
      @transition = EndState::StateMapping[transition]
      @failure_messages = []
      @guards = []
      @concluders = []
      @required_params = []
    end

    def matches?(actual)
      @machine = actual
      verify
    end

    def failure_message
      failure_messages.join("\n")
    end

    def description
      "have transition #{transition}"
    end

    def with_guards(*guards)
      @guards += Array(guards).flatten
      self
    end

    def with_concluders(*concluders)
      @concluders += Array(concluders).flatten
      self
    end

    def with_required_params(*params)
      @required_params += Array(params).flatten
      self
    end

    alias_method :with_guard, :with_guards
    alias_method :with_concluder, :with_concluders
    alias_method :with_required_param, :with_required_params

    # Backward compatibility
    # Finalizer is deprecated
    alias_method :with_finalizer, :with_concluder
    alias_method :with_finalizers, :with_concluders
    alias_method :finalizers, :concluders

    private

    def transition_configuration
      @tc = machine.transition_configurations[transition]
    end

    def has_guard?(guard)
      transition_configuration.guards.include?(guard)
    end

    def has_concluder?(concluder)
      transition_configuration.concluders.include?(concluder)
    end

    def has_required_param?(param)
      transition_configuration.required_params.include?(param)
    end

    def add_failure(suffix)
      failure_messages << "expected transition #{transition} #{suffix}"
    end

    def verify
      if transition_configuration.nil?
        add_failure('to be defined')
      else
        verify_guards
        verify_concluders
        verify_required_params
      end

      failure_messages.empty?
    end

    def verify_guards
      guards.map do |guard|
        add_failure("to have guard #{guard.name}") unless has_guard?(guard)
      end
    end

    def verify_concluders
      concluders.map do |concluder|
        add_failure("to have concluder #{concluder.name}") unless has_concluder?(concluder)
      end
    end

    def verify_required_params
      required_params.each do |param|
        add_failure("to have required param #{param}") unless has_required_param?(param)
      end
    end
  end
end

include EndStateMatchers
