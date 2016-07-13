require_relative '../gilmour'

gilmour = Gilmour.new

gilmour.reply_to 'echo_service', excl_group: 'echo_service', timeout: 1 do
  puts request.body
end

gilmour.request!('Hello: 1', 'echo_service',
                 timeout: 5) do |resp, code|
  puts resp, code
  if code.to_i != 200
    $stderr.puts 'Something went wrong in the response! Aborting'
    exit
  end
end

gilmour.slot 'echo_slot' do
  puts 'Sent push notification for -'
  puts request.body
end

gilmour.signal!('Hello: 2', 'echo_slot')
