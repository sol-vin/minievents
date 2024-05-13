require "./test"
MiniEvents.install

success1 = false 
sucess2 = false
class MyTest
  event MyEvent, x : self
end

t = MyTest.new
t.on_my_event(name: "mytest") do
  success1 = true
end

on(MyTest::MyEvent) do |test|
  success2 = true
end

emit MyTest::MyEvent, t

class MyTest2
  event MyEvent, x : self, i : Int32

  def test
    emit MyEvent, self, 10
  end
end

success2 = false

t = MyTest2.new
on(MyTest2::MyEvent, name: "mytest2") do |test, i|
  success2 = true if i == 10
end
t.test

struct MyTest3
  single_event MyEvent, x : self, i : Int32

  def test
    emit MyEvent, self, 10
  end
end

success3 = false

test3 = MyTest3.new
test3.on_my_event do
  success3 = true
end
test3.test

struct MyTest4
  single_event MyEvent, x : self
end

test4 = MyTest4.new
emit MyTest4::MyEvent, test4


if success1 && success2 && success3
  puts SUCCESS
else
  puts FAILURE
end
