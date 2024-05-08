require "./minievents"
MiniEvents.install

# Event can be made out here
event LeverOn
class Lever
  # Or in here (it doesn't matter)
  event LeverOff

  # Attach our events to this class
  attach LeverOn
  attach LeverOff

  @state = false

  def toggle
    if @state == true
      emit_lever_off # Created by `attach Off`
      @state = false
    else
      emit_lever_on # Created by `attach On`
      @state = true
    end
  end
end

lever = Lever.new

lever.on_lever_on do
  puts "ON!"
end

lever.on_lever_off do
  puts "off"
end

lever.toggle
lever.toggle
lever.toggle
lever.toggle
lever.toggle