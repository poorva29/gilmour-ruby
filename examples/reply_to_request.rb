require_relative '../lib/gilmour'

gilmour = Gilmour::Gilmour.new

# Example - reply_to with no excel_group
opts = Gilmour::HandlerOpts.new(timeout: 5)
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
resp =  resp.next
puts resp
unless resp['messages']['result'].keys.include?('next')
  puts 'key `next` not found'
end

# Example - Unsubscribe reply_to
gilmour.unsubscribe_reply('echo_service')

opts = Gilmour::RequestOpts.new(timeout: 5)
req = Gilmour::Request.new('echo_service', opts)
resp = req.execute!('first' => 1, 'second' => 2)
if resp.code.to_i != 200
  puts 'Something went wrong in the response . Aborting !'
  exit
end
puts 'For echo_service'
resp = resp.next
puts resp
unless resp['messages']['result'] == 'No active listeners for: echo_service'
  puts 'Listeners not unsubscribed properly'
end

# Example - reply_to with no timeout but has excel_group
opts = Gilmour::HandlerOpts.new(excl_group: 'echo_service1')
gilmour.reply_to 'echo_service1', opts do |request, response|
  data = request.data
  response.data = data
end

req = Gilmour::Request.new('echo_service1')
resp = req.execute!('Hello: 1')
if resp.code.to_i != 200
  puts 'Something went wrong in the response . Aborting !'
  exit
end
puts 'For echo_service1'
resp = resp.next
puts resp
unless resp['messages']['result'] == 'Hello: 1'
  puts 'Expected response : Hello: 1'
end

# Example - reply_to with no timeout and excel_group
gilmour.reply_to 'echo_service2' do |request, response|
  data = request.data
  response.data = data
end

req = Gilmour::Request.new('echo_service2')
resp = req.execute!('Hello: 2')
if resp.code.to_i != 200
  puts 'Something went wrong in the response . Aborting !'
  exit
end
puts 'For echo_service2'
resp = resp.next
puts resp
unless resp['messages']['result'] == 'Hello: 2'
  puts 'Expected response : Hello: 2'
end

# Example - reply_to with timeout and excel_group
opts = Gilmour::HandlerOpts.new(timeout: 5, excl_group: 'echo_service3')
gilmour.reply_to 'echo_service3', opts do |request, response|
  data = request.data
  response.data = data
end

opts = Gilmour::RequestOpts.new(timeout: 10)
req = Gilmour::Request.new('echo_service3', opts)
resp = req.execute!('Hello: 3')
if resp.code.to_i != 200
  puts 'Something went wrong in the response . Aborting !'
  exit
end
puts 'For echo_service3'
resp = resp.next
puts resp
unless resp['messages']['result'] == 'Hello: 3'
  puts 'Expected response : Hello: 3'
end

# Example - request takes with option , only hash is supported as of now
opts = Gilmour::HandlerOpts.new(timeout: 5, excl_group: 'echo_service3')
gilmour.reply_to 'echo_service3', opts do |request, response|
  data = request.data
  response.data = data
end

req = Gilmour::Request.new('echo_service3', nil).with(first: 1)
resp = req.execute!(second: 2)
if resp.code.to_i != 200
  puts 'Something went wrong in the response . Aborting !'
  exit
end
puts 'For echo_service3'
resp =  resp.next
puts resp
resp['messages']['result'].keys.each do |key|
  puts "key #{key} not found" unless %w(first second).include?(key)
end

# Example - fetch all the subscribed services
resp = gilmour.subscribed_services
puts 'Services cannot be nil' if resp['services'].nil?

gilmour.stop
