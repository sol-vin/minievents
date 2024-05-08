require "../spec/spec_helper"

success1 = false
success2 = false

event MyEvent1

on(MyEvent1) { success1 = true }

emit MyEvent1 

event ::MyEvent2

on(::MyEvent2) { success2 = true }

emit ::MyEvent2 


if success1 && success2
  puts SUCCESS
else
  puts FAILURE
end