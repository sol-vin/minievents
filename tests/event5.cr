require "./test"
total = 0 
module A
  MiniEvents.install(::Event)

  event MyEvent, x : Int32
  event ::MyEvent2, x : Int32

  on(MyEvent) do |x|
    total += x
  end

  on(::MyEvent2) do |x|
    total += x
  end

  def self.trigger
    emit MyEvent, 10
    emit ::MyEvent2, 20
  end
end

A.trigger
A.emit ::MyEvent2, 30
A.emit A::MyEvent, 40

if total == 100
  puts SUCCESS
else
  puts FAILURE 
end
