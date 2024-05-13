require "./test"
MiniEvents.install

total = 0

class MyTest
  event MyEvent, x : self
end

t = MyTest.new
t.on_my_event(once: true) do
  total += 1
end

emit MyTest::MyEvent, t
emit MyTest::MyEvent, t

if total == 1
  puts SUCCESS
else
  puts FAILURE, total
end
