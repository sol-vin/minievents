require "./minievents"
MiniEvents.install

class Lever
  # Event can be made here
  event Off, me : self

  @state = false

  def toggle
    if @state == true
      emit Off, self
      @state = false
    else
      emit On, self
      @state = true
    end
  end
end
# Or out here
event Lever::On, me : Lever

lever1 = Lever.new
lever2 = Lever.new

# # Cant hook this because it was made outside 
# lever.on_on do
#   puts "ON!"
# end

on(Lever::On) do |lever|
  puts "ON!"
end

# This is localized to this instance only
lever1.on_off do
  puts "~off~"
end

on(Lever::Off) do |lever|
  puts "~also off~"
end

lever1.toggle
lever1.toggle
lever1.toggle
lever1.toggle
lever1.toggle
puts
lever2.toggle
lever2.toggle
lever2.toggle
lever2.toggle
lever2.toggle