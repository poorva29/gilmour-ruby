require_relative '../gilmour'

gilmour = Gilmour.new

gilmour.reply_to 'echo_service', excl_group: 'echo_service',
                                 timeout: 1 do |request, response|
  data = request.data
  first = data['first']
  second = data['second']
  response.set_data('next' => first + second)
end

gilmour.request!({ 'first' => 1, 'second' => 2 },
                 'echo_service', timeout: 5) do |resp, code|
  puts 'For echo_service', resp
  if code.to_i != 200
    $stderr.puts 'Something went wrong in the response! Aborting'
    exit
  end
end

gilmour.reply_to 'echo_service1',
                 excl_group: 'echo_service1', timeout: 1 do |request, response|
  data = request.data
  puts 'For echo_service1', data
  response.set_data(data)
end

gilmour.request!('Hello: 1', 'echo_service1',
                 timeout: 5) do |resp, code|
  puts resp
  if code.to_i != 200
    $stderr.puts 'Something went wrong in the response! Aborting'
    exit
  end
end

gilmour.slot 'echo_slot' do |request|
  puts 'Sent push notification for -', request.data
end

gilmour.signal!('Hello: 2', 'echo_slot')
sleep(1)
gilmour.stop
