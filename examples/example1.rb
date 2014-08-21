$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'end_state'

class Easy < EndState::Guard
  def will_allow?
    true
  end
end

class NoOp < EndState::Concluder
  def call
    true
  end

  def rollback
    true
  end
end

class CustomAction < EndState::Action
  def call
    super
  end
end

class Machine < EndState::StateMachine
  transition a: :b do |t|
    t.guard Easy
    t.persistence_on
  end

  transition b: :c do |t|
    t.custom_action CustomAction
    t.persistence_on
  end

  transition [:b, :c] => :a do |t|
    t.concluder NoOp
    t.persistence_on
  end
end

class StatefulObject
  attr_accessor :state

  def initialize(state)
    @state = state
  end

  def save
    puts "Saved with state: #{state}"
    true
  end
end

object = StatefulObject.new(:a)
machine = Machine.new(object)

puts "The machine's class is: #{machine.class.name}"
puts "The machine's object class is: #{machine.object.class.name}"
puts

%i( b c a c).each do |state|
  puts "Attempting to move to #{state}"
  machine.transition state
  puts "State: #{machine.state}"
  predicate = "#{state}?".to_sym
  puts "#{state}?: #{machine.send(predicate)}"
  puts
end
