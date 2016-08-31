require_relative '../lib/gilmour'

gilmour = Gilmour::Gilmour.new

# Example - Slot with excel_group and timeout
opts = Gilmour::HandlerOpts.new(timeout: 5, excl_group: 'echo_slot')
gilmour.slot 'echo_slot', opts do |request|
  puts 'For echo_slot -', request.data
end

gilmour.signal!({ 'first' => 1, 'second' => 2 }, 'echo_slot')

# Example - Unsubscribe slot
gilmour.unsubscribe_slot('echo_slot')

gilmour.signal!({ 'first' => 1, 'second' => 2 }, 'echo_slot')

# Example - Slot with excel_group
opts = Gilmour::HandlerOpts.new(excl_group: 'echo_slot1')
gilmour.slot 'echo_slot1', opts do |request|
  puts 'For echo_slot1 -', request.data
end

gilmour.signal!('Hello: 1', 'echo_slot1')

# Example - Slot with no handler options
gilmour.slot 'echo_slot2' do |request|
  puts 'For echo_slot2 -', request.data
end

gilmour.signal!('Hello: 2', 'echo_slot2')

# Example - Get subscribed slots
resp = gilmour.subscribed_slots
puts 'Slots cannot be nil' if resp['slots'].nil?

gilmour.stop
