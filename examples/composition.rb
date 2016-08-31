require_relative '../lib/gilmour'
gilmour = Gilmour::Gilmour.new

gilmour.reply_to 'compose-one' do |request, response|
  data = request.data
  data['ack-one'] = 'one'
  response.data = data
end

gilmour.reply_to 'compose-two' do |request, response|
  data = request.data
  data['ack-two'] = 'two'
  response.data = data
end

gilmour.reply_to 'compose-three' do |request, response|
  data = request.data
  data['ack-three'] = 'three'
  response.data = data
end

gilmour.reply_to 'compose-bad-two' do |_, _|
  raise 'bad-two'
end

# Example 1 - Pipe with only requests
pipe = Gilmour::Pipe.new(
  Gilmour::Request.new('compose-one').with('merge-one' => 1),
  Gilmour::Request.new('compose-two').with('merge-two' => 1)
)
resp = pipe.execute!('input' => 1)
if resp.code.to_i != 200
  puts 'Something went wrong in the response . Aborting !'
  exit
end
resp = resp.next
['ack-one', 'ack-two', 'input', 'merge-one', 'merge-two'].each do |key|
  if resp[key].nil?
    puts 'For composition'
    puts "Key = #{key} not found !"
  end
end

# # Example 2 - Pipe with requests, parallel and lambda
# def converge(request, response)
#   data = request.data
#   res = []
#   data.each do |d|
#     res[d['WordLength'] - 3] = d['Words']
#   end
#   response.data = res
# end

# URL = 'https://s3-us-west-1.amazonaws.com/ds-data-sample/test.txt'
# pipe = Gilmour::Pipe.new(
#   Gilmour::Request.new('example.fetch'),
#   Gilmour::Request.new('example.words'),
#   Gilmour::Request.new('example.stopfilter'),
#   Gilmour::Request.new('example.count'),
#   Gilmour::Parallel.new(
#     Gilmour::Request.new('example.popular3'),
#     Gilmour::Request.new('example.popular5'),
#     Gilmour::Request.new('example.popular4')
#   ),
#   Gilmour::Lambda.new(:converge)
# )
# puts pipe.pipe_hash
# resp = pipe.execute!(URL)
# puts 'For composition'
# resp.next.each do |popular_words|
#   puts 'Popular Words: ', popular_words
# end
# if resp.code.to_i != 200
#   puts 'Something went wrong in the response . Aborting !'
#   exit
# end

# Example 3 - Lambda only
KEY = 'merge'
def converge1(request, response)
  data = request.data
  data[KEY] = 1
  response.data = data
end

lambda1 = Gilmour::Lambda.new(:converge1)
resp = lambda1.execute!(arg: 1)
if resp.next['merge']
  puts "Key \'#{KEY}\' found"
else
  puts "Key \'#{KEY}\' not found !"
end

# Example 4 -
KEY1 = 'fake-two'
def converge2(request, response)
  data = request.data
  data[KEY1] = 1
  response.data = data
end

pipe = Gilmour::Pipe.new(
  Gilmour::Lambda.new(:converge2),
  Gilmour::Request.new('compose-two').with('merge-two' => 1)
)

andand = Gilmour::AndAnd.new(
  Gilmour::Request.new('compose-one').with('merge-one' => 1),
  pipe
)

resp = andand.execute!(input: 1)
resp = resp.next
['merge', 'ack-one'].each do |key, _|
  puts "Must not have #{key} in final output" unless resp[key].nil?
end

['input', 'fake-two', 'ack-two'].each do |key, _|
  puts "Must have #{key} in final output" if resp[key].nil?
end

# Example 5 -
oror = Gilmour::OrOr.new(
  Gilmour::Request.new('compose-bad-two'),
  Gilmour::Request.new('compose-one'),
  Gilmour::Request.new('compose-three')
)

resp = oror.execute!(input: 1)
resp = resp.next
['ack-three'].each do |key|
  puts "Must not have #{key} in final output" unless resp[key].nil?
end

['input', 'ack-one'].each do |key|
  puts "Must have #{key} in final output" if resp[key].nil?
end

# Example 6 -
oror = Gilmour::OrOr.new(
  Gilmour::Request.new('compose-bad-two'),
  Gilmour::Parallel.new(
    Gilmour::Request.new('compose-one'),
    Gilmour::Request.new('compose-two'),
    Gilmour::Request.new('compose-three')
  ),
  Gilmour::Request.new('compose-one')
)
resp = oror.execute!(input: 1)
resp = resp.next
resp.each do |objts|
  puts 'Must have key: input in final output' if objts['input'].nil?
end

# Example 7 -
parallel = Gilmour::Parallel.new(
  Gilmour::Parallel.new(
    Gilmour::Request.new('compose-one').with('1a' => 1),
    Gilmour::Request.new('compose-two').with('2a' => 1),
    Gilmour::Request.new('compose-three').with('3a' => 1)
  ),
  Gilmour::Parallel.new(
    Gilmour::Request.new('compose-one').with('1b' => 1),
    Gilmour::Request.new('compose-two').with('2b' => 1),
    Gilmour::Request.new('compose-three').with('3b' => 1)
  )
)
resp = parallel.execute!(input: 1)
resp = resp.next
resp.each do |objts|
  objts.each do |o|
    puts 'Must have key: input in final output' if o['input'].nil?
  end
end

# Example 8 -
newbatch = Gilmour::NewBatch.new(
  Gilmour::Request.new('compose-one').with('merge' => 1),
  Gilmour::Request.new('compose-two').with('merge-two' => 1)
)
resp = newbatch.execute!(input: 1)
resp = resp.next
['merge', 'ack-one'].each do |key|
  puts "Must not have #{key} in final output" unless resp[key].nil?
end

['input', 'merge-two', 'ack-two'].each do |key|
  puts "Must have #{key} in final output" if resp[key].nil?
end

gilmour.stop
