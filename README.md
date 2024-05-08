# minievents

A small/simple event architecture for Crystal. 

## Installation

Add to `shard.yml`
```yml
  dependencies:
    minievents:
      github: sol-vin/minievents
```

In your project's main:
```crystal
require "minievents"
MiniEvents.install
```

## Usage

Minievents can be used in both a "global" mode and an "instance" mode.

### Basic global usage:
```crystal
# Create an event
event Event1

# Create an event with arguments
event Event2, x : Int32, y : Int32

# Set up a callback for the event
on(Event1) do
  puts "Event1: Triggered!"
end

# Set as many as you want!
on(Event1) do
  puts "Event1: Also Triggered!"
end

on(Event2) do |x, y|
  puts "Event2: Triggered at #{x}, #{y}!"
end

# Emit the events

emit Event1
emit Event2, 100, 200
```

#### Output:
```
Event1: Triggered!
Event1: Also Triggered!
Event2: Triggered at 100, 200!
```

### Basic instance usage:
```crystal

# Event can be made out here
event LeverOn
class Lever
  # Or in here (it doesn't matter)
  event LeverOff

  # Attach our events to this class
  attach LeverOn
  attach LeverOff

  @state = false

  def toggle
    if @state == true
      emit_lever_off # Created by `attach Off`
      @state = false
    else
      emit_lever_on # Created by `attach On`
      @state = true
    end
  end
end

lever = Lever.new

lever.on_lever_on do
  puts "ON!"
end

lever.on_lever_off do
  puts "off"
end

lever.toggle
lever.toggle
lever.toggle
lever.toggle
lever.toggle
```

#### Output
```
ON!
off
ON!
off
ON!
```

### Default Names

By default the base event is called `MiniEvents::Event` and all of these events are collected under the namespace `MiniEvents::Events`

### Advanced Configuration
You can change what the default event name and event collection is named when using `MiniEvents.install`.

```crystal
require "minievents"
MiniEvents.install(MyClass::Event, MyClass::Events)
```

You can also install multiple instances of MiniEvents into a single program, but they will all be link so the systems will be linked.

```crystal
require "minievents"


module A
  MiniEvents.install(Event)

  event MyEvent, x : Int32

  on(MyEvent) do |x|
    puts "A"
  end

  def self.trigger
    emit MyEvent, 10
  end
end


module B
  MiniEvents.install(Event)
  
  event MyEvent, x : Int32
  
  on(MyEvent) do |x|
    puts "B"
  end
  
  def self.trigger
    emit MyEvent, 20
  end
end

A.trigger
B.trigger

A.emit ::A::MyEvent, 30
B.emit ::B::MyEvent , 40

# Systems are coupled so you can still do this
A.emit ::B::MyEvent, 50
B.emit ::A::MyEvent , 60
```

#### Output
```
A
B
A
B
B
A
```

## Development

Fork it or whatever IDC

## Contributing

1. Fork it (<https://github.com/your-github-user/minievents/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Ian Rash](https://github.com/your-github-user) - creator and maintainer
