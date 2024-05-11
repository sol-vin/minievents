require "./test"
MiniEvents.install

success = true 

class MyTest
  event MyEvent, x : self

  attach_self MyEvent

  def test
    emit_my_event
  end
end

MyTest.new.test

if success
  puts SUCCESS
else
  puts FAILURE
end
