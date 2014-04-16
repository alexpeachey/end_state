# EndStateMatchers

Custom RSpec matchers for EndState state machines.

## Installation

Add this line to your application's Gemfile in the test group:

    gem 'end_state_matchers'

And then execute:

    $ bundle

## Usage

```ruby
describe Machine do
  specify { expect(Machine).to have_transition(a: :b).with_guard(MyGuard).with_finalizer(MyFinalizer) }
  specify { expect(Machine).not_to have_transition(a: :c) }
end
```

## Contributing

1. Fork it ( http://github.com/<my-github-username>/end_state_matchers/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
