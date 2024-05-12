require "./test"
MiniEvents.install

success1 = false
success2 = false
success3 = false
success4 = false

event MyEvent1

on(MyEvent1) { success1 = true }

emit MyEvent1 

event ::MyEvent2

on(::MyEvent2) { success2 = true }

emit ::MyEvent2

event ::MyEvent3, i : Int32

on(::MyEvent3) { |i| success3 = true if i == 10 }

emit ::MyEvent3, 10

event ::MyEvent4, i : Int32, j : Float64

on(::MyEvent4) { |i, j| success4 = true if i == 10 && j > 3}

emit ::MyEvent4, 10, 3.4


if success1 && success2 && success3 && success4
  puts SUCCESS
else
  puts FAILURE
end