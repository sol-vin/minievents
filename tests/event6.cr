require "./test"
total = 0 
module A
  MiniEvents.install(Event)

  event MyEvent, x : Int32

  on(MyEvent) do |x|
    total += x
  end

  def self.trigger
    emit MyEvent, 10
  end
end


module B
  MiniEvents.install(Event)
  
  event MyEvent, x : Int32
  
  on(MyEvent) do |x|
    total += x
  end
  
  def self.trigger
    emit MyEvent, 20
  end
end

A.trigger
B.trigger

A.emit ::A::MyEvent, 30
B.emit ::B::MyEvent , 40

A.emit ::B::MyEvent, 50
B.emit ::A::MyEvent , 60

if total == 210
  puts SUCCESS
else
  puts FAILURE 
end