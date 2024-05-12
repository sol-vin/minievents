require "./test"
MiniEvents.install

success = false 

class MyTest
  attach_event MyEvent, x : self

  def test
    emit MyEvent, self
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
