require "./test"
MiniEvents.install

success = false 

class MyTest
  event MyEvent, x : self

  attach_self MyEvent

  def test
    emit_my_event
  end
end

t = MyTest.new
t.on_my_event do
  success = true
end
t.test

if success
  puts SUCCESS
else
  puts FAILURE
end
