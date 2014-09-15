require 'delegate'
require 'end_state/version'
require 'end_state/errors'
require 'end_state/messages'
require 'end_state/guard'
require 'end_state/concluder'
require 'end_state/concluders'
require 'end_state/transition'
require 'end_state/transition_configuration'
require 'end_state/state_mapping'
require 'end_state/action'
require 'end_state/state_machine'

begin
  require 'graphviz'
  require 'end_state/graph'
rescue LoadError
end

module EndState
end
