require_relative '../lib/gilmour'

gilmour = Gilmour::Gilmour.new

opts = Gilmour::HandlerOpts.new(timeout: 5, excl_group: 'echo_service')
gilmour.reply_to 'echo_service', opts do |request, response|
  data = request.data
  first = data['first']
  second = data['second']
  response.data = { 'next' => first + second }
end

opts = Gilmour::RequestOpts.new(timeout: 5)
req = Gilmour::Request.new('echo_service', opts)
resp = req.execute!('first' => 1, 'second' => 2)
if resp.code.to_i != 200
  puts 'Something went wrong in the response . Aborting !'
  exit
end
puts 'For echo_service'
puts resp.data

opts = Gilmour::HandlerOpts.new(timeout: 5, excl_group: 'echo_service1')
gilmour.reply_to 'echo_service1', opts do |request, response|
  data = request.data
  response.data = data
end

opts = Gilmour::RequestOpts.new(timeout: 5)
req = Gilmour::Request.new('echo_service1', opts)
resp = req.execute!('Hello: 1')
if resp.code.to_i != 200
  puts 'Something went wrong in the response . Aborting !'
  exit
end
puts 'For echo_service1'
puts resp.data

opts = Gilmour::HandlerOpts.new(timeout: 5, excl_group: 'echo_service')
gilmour.slot 'echo_slot', opts do |request|
  puts 'Sent push notification for -', request.data
end

gilmour.signal!({ 'first' => 1, 'second' => 2 }, 'echo_slot')
sleep(2)

gilmour.stop
