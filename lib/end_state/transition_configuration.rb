module EndState
  class TransitionConfiguration
    attr_reader :action, :allowed_params, :concluders, :guards, :required_params

    def initialize
      @action = Action
      @allowed_params = []
      @concluders = []
      @guards = []
      @required_params = []
    end

    def custom_action(action)
      @action = action
    end

    def guard(*guards)
      Array(guards).flatten.each { |guard| self.guards << guard }
    end

    def concluder(*concluders)
      Array(concluders).flatten.each { |concluder| self.concluders << concluder }
    end

    def persistence_on
      concluder Concluders::Persistence
    end

    def allow_params(*params)
      Array(params).flatten.each do |param|
        append_unless_included(:allowed_params, param)
      end
    end

    def require_params(*params)
      Array(params).flatten.each do |param|
        append_unless_included(:allowed_params, param)
        append_unless_included(:required_params, param)
      end
    end

    private

    def append_unless_included(name, value)
      attribute = self.send(name)
      attribute << value unless attribute.include? value
    end
  end
end
