# EndState

EndState is an unobtrusive way to add state machines to your application.

An `EndState::StateMachine` acts as a decorator of sorts for your stateful object.
Your stateful object does not need to know it is being used in a state machine and
only needs to respond to `state` and `state=`. (This is customizable)

The control flow for guarding against transitions and performing post-transition
operations is handled by classes you create allowing maximum separation of responsibilities.

## Installation

Add this line to your application's Gemfile:

    gem 'end_state'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install end_state

## StateMachine

Create a state machine by subclassing `EndState::StateMachine`.

```ruby
class Machine < EndState::StateMachine
  transition a: :b, as: :go
  transition b: :c
  transition [:b, :c] => :a
end
```

Use it by wrapping a stateful object.

```ruby
class StatefulObject
  attr_accessor :state

  def initialize(state)
    @state = state
  end
end

machine = Machine.new(StatefulObject.new(:a))

machine.transition :b       # => true
machine.state               # => :b
machine.b?                  # => true
machine.c!                  # => true
machine.state               # => :c
machine.can_transition? :b  # => false
machine.can_transition? :a  # => true
machine.b!                  # => false
machine.a!                  # => true
machine.state               # => :a
machine.go!                 # => :true
machine.state               # => :b
```

## Initial State

If you wrap an object that currently has `nil` as the state, the state will be set to `:__nil__`.
You can change this using the `set_initial_state` method.

```ruby
class Machine < EndState::StateMachine
  set_initial_state :first
end
```

## Guards

Guards can be created by subclassing `EndState::Guard`. Your class will be provided access to:

* `object` - The wrapped object.
* `state` - The desired state.
* `params` - A hash of params passed when calling transition on the machine.

Your class should implement the `will_allow?` method which must return true or false.

Optionally you can implement the `passed` and/or `failed` methods which will be called after the guard passes or fails.
These will only be called during the check performed during the transition and will not be fired when asking `can_transition?`.
These hooks can be useful for things like logging.

The wrapped object has an array `failure_messages` available for tracking reasons for invalid transitions. You may shovel
a reason (string) into this if you want to provide information on why your guard failed. You can also use the helper method in
the `Guard` class called `add_error` which takes a string.

The wrapped object has an array `success_messages` available for tracking reasons for valid transitions. You may shovel
a reason (string) into this if you want to provide information on why your guard passed. You can also use the helper method in
the `Guard` class called `add_success` which takes a string.

```ruby
class EasyGuard < EndState::Guard
  def will_allow?
    true
  end

  def failed
    Rails.logger.error "Failed to transition to state #{state} from #{object.state}."
  end
end
```

A guard can be added to the transition definition:

```ruby
class Machine < EndState::StateMachine
  transition a: :b do |t|
    t.guard EasyGuard
    t.guard SomeOtherGuard
  end
end
```

## Concluders

Concluders can be created by subclassing `EndState::Concluder`. Your class will be provided access to:

* `object` - The wrapped object that has been transitioned.
* `state` - The previous state.
* `params` - A hash of params passed when calling transition on the machine.

Your class should implement the `call` method which should return true or false as to whether it was successful or not.

If your concluder returns false, the transition will be "rolled back" and the failing transition, as well as all previous transitions
will be rolled back. The roll back is performed by calling `rollback` on the concluder. During the roll back the concluder will be
set up a little differently and you have access to:

* `object` - The wrapped object that has been rolled back.
* `state` - The attempted desired state.
* `params` - A hash of params passed when calling transition on the machine.

The wrapped object has an array `failure_messages` available for tracking reasons for invalid transitions. You may shovel
a reason (string) into this if you want to provide information on why your concluder failed. You can also use the helper method in
the `Concluder` class called `add_error` which takes a string.

The wrapped object has an array `success_messages` available for tracking reasons for valid transitions. You may shovel
a reason (string) into this if you want to provide information on why your concluder succeeded. You can also use the helper method in
the `Concluder` class called `add_success` which takes a string.

```ruby
class WrapUp < EndState::Concluder
  def call
    # Some important processing
    true
  end

  def rollback
    # Undo stuff that shouldn't have been done.
  end
end
```

A concluder can be added to the transition definition:

```ruby
class Machine < EndState::StateMachine
  transition a: :b do |t|
    t.concluder WrapUp
  end
end
```

Since it is a common use case, a concluder is included which will call `save` on the wrapped object if it responds to `save`.
You can use this with a convience method in your transition definition:

```ruby
class Machine < EndState::StateMachine
  transition a: :b do |t|
    t.persistence_on
  end
end
```

## Action

By default, a transition from one state to another is handled by `EndState` and only changes the state to the new state.
This is the recommended default and you should have a good reason to do something more or different.
If you really want to do something different though you can create a class that subclasses `EndState::Action` and implement
the `call` method.

You will have access to:

* `object` - The wrapped object.
* `state` - The desired state.

```ruby
class MyCustomAction < EndState::Action
  def call
    # Do something special
    super
  end
end
```

```ruby
class Machine < EndState::StateMachine
  transition a: :b do |t|
    t.custom_action MyCustomAction
  end
end
```

## Events

By using the `as` option in a transition definition you are creating an event representing that transition.
This can allow you to exercise the machine in a more natural "verb" style interaction. When using `as` event
definitions you can optionally set a `blocked` message on the transition. When the event is executed, if the
machine is not in a state maching the initial state of the event, the message is added to the `failure_messages`
array on the machine.

```
class Machine < EndState::StateMachine
  transition a: :b, as: :go do |t|
    t.blocked 'Cannot go!'
  end
end

machine = Machine.new(StatefulObject.new(:a))

machine.go!                 # => true
machine.state               # => :b
machine.go!                 # => false
machine.failure_messages    # => ['Cannot go!']
```

## State storage

You may want to use an attribute other than `state` to track the state of the machine.

```ruby
class Machine < EndState::StateMachine
  state_attribute :status
end
```

Depending on how you persist the `state` (if at all) you may want what is stored in `state` to be a string instead
of a symbol. You can tell the machine this preference.

```ruby
class Machine < EndState::StateMachine
  store_states_as_strings!
end
```

## Exceptions for failing Transitions

By default `transition` will only raise an error, `EndState::UnknownState`, if called with a state that doesn't exist.
All other failures, such as missing transition, guard failure, or concluder failure will silently just return `false` and not
transition to the new state.

You also have the option to use `transition!` which will instead raise an error for failures. If your guards and/or concluders
add to the `failure_messages` array then they will be included in the error message.

Additionally, if you would like to treat all transitions as hard and raise an error you can set that in the machine definition.

```ruby
class Machine < EndState::StateMachine
  treat_all_transitions_as_hard!
end
```

## Graphing

If you install `GraphViz` and the gem `ruby-graphviz` you can create images representing your state machines.

`EndState::Graph.new(MyMachine).draw.output png: 'my_machine.png'`

If you use events in your machine, it will add the events along the arrow representing the transition. If you don't want this,
pass in false when contructing the Graph.

`EndState::Graph.new(MyMachine, false).draw.output png: 'my_machine.png'`

## Testing

Included is a custom RSpec matcher for testing your machines.

In your `spec_helper.rb` add:

```ruby
require 'end_state_matchers'
```

In the spec for your state machine:

```ruby
describe Machine do
  specify { expect(Machine).to have_transition(a: :b).with_guard(MyGuard) }
  specify { expect(Machine).to have_transition(a: :b).with_concluder(MyConcluder) }
  specify { expect(Machine).to have_transition(a: :b).with_guard(MyGuard).with_concluder(MyConcluder) }
  specify { expect(Machine).to have_transition(a: :b).with_guards(MyGuard, AnotherGuard) }
  specify { expect(Machine).to have_transition(a: :b).with_concluders(MyConcluder, AnotherConcluder) }
  specify { expect(Machine).not_to have_transition(a: :c) }
end
```

## Contributing

1. Fork it ( https://github.com/Originate/end_state/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
