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
require "minievents"
MiniEvents.install

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
require "minievents"
MiniEvents.install

class Lever
  # Event can be made here
  # This adds on_event(on_off in this case)
  event Off, me : self

  @state = false

  def toggle
    if @state == true
      emit Off, self
      @state = false
    else
      emit On, self
      @state = true
    end
  end
end
# Or out here (however this does not hook up on_event methods unless made in the class)
event Lever::On, me : Lever

lever1 = Lever.new
lever2 = Lever.new

# # Cant hook this because it was made outside 
# lever.on_on do
#   puts "ON!"
# end

on(Lever::On) do |lever|
  puts "ON!"
end

# This is localized to this instance only
lever1.on_off do
  puts "~off~"
end

on(Lever::Off) do |lever|
  puts "~also off~"
end

lever1.toggle
lever1.toggle
lever1.toggle
lever1.toggle
lever1.toggle
puts
lever2.toggle
lever2.toggle
lever2.toggle
lever2.toggle
lever2.toggle
```

#### Output
```
ON!
~off~
~also off~
ON!
~off~
~also off~
ON!

ON!
~also off~
ON!
~also off~
ON!
```

### Default Names

By default the base event is called `::MiniEvents::Event`

### Advanced Configuration
You can change what the default event name is named when using `::MiniEvents.install`.

```crystal
require "minievents"
MiniEvents.install(::MyClass::Event)
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
  MiniEvents.install(Event) # Installs event to B::Event
  
  event MyEvent, x : Int32
  
  on(MyEvent) do |x|
    puts "B"
  end
  
  def self.trigger
    emit MyEvent, 20
  end
end

# Emit in here
A.trigger
B.trigger

# Or emit out here
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

# Usage per instance

Classes can be made to allow their instances to have custom callbacks. This happens automatically when the event is created inside of a class and takes its first argument as it's own type.

```crystal
require "minievents"
MiniEvents.install

class MyClass
  event MyEvent
  event MySelfEvent, me : self
  event MySelfEvent2, me : self, x : Int32
end

m = MyClass.new

# Can't  do this because MyEvent doesn't take a self param
# m.on_my_event do
#   puts "MySelfEvent"
# end

m.on_my_self_event do # Doesn't take the me argument here
  puts "MySelfEvent"
end

m.on_my_self_event2 do |x| # Doesn't take the me argument here
  puts "MySelfEvent2 #{x}"
end

emit MyClass::MyEvent
emit MyClass::MySelfEvent, m # You include the object emitted here
emit MyClass::MySelfEvent2, m, 500 # You include the object emitted here
```

#### Output
```
MySelfEvent
MySelfEvent2 500
```

If you make an event outside of it's containing class it cannot hook up the `#on_event`, maybe there is a way to fix that in the future IDK.

# Usage on `struct`s
Structs cannot use normal `event` because it has an array.

However, it can use the mono-callback class `single_event`. Single events work just like regular events but only have one callback.

Use this just like you would `event`, just without the ability to use multiple callbacks. It will also attempt to attach to a single instance if the first argument is a `self`.

```crystal
struct MyStruct
  single_event MyEvent
  single_event MySelfEvent
  single_event MySelfEvent2, i : self
end

emit MyStruct::MyEvent
emit MyStruct::MySelfEvent

s = MyStruct.new
s.on_my_self_event2 do 
  puts s
end

emit MyStruct::MySelfEvent2, s
```
## Development

Fork it or whatever IDC

## Contributing

1. Fork it (<https://github.com/sol-vin/minievents/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Ian Rash](https://github.com/sol-vin) - creator and maintainer
