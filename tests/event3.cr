require "./test"
MiniEvents.install

success = true 

class MyTest
  event MyEvent, x : MyTest
  
  # on(MyEvent) do |x|
  #   success = true
  # end

  # def test
  #   emit MyEvent, self
  # end
end

# MyTest.new.test

if success
  puts SUCCESS
else
  puts FAILURE
end
