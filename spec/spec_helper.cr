require "spec"
require "../src/minievents"
require "../tests/test"
MiniEvents.install

macro make_event_test(x)
  ({{ run("../tests/event#{x}.cr").stringify }} =~ /OK/).should_not be_nil
end

