require "./test"
MiniEvents.install

success = false 

class MyTest
  attach_event MyEvent, x : self, y : Int32

  def test
    emit MyEvent, self, 10
  end
end

t = MyTest.new
t.on_my_event do |x|
  success = true if x == 10
end
t.test

if success
  puts SUCCESS
else
  puts FAILURE
end
