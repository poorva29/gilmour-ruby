module Common
  def parallel_str
    String.new('parallel' + Random.rand(100).to_s)
  end

  def request_str
    String.new('requests' + Random.rand(100).to_s)
  end

  def lambda_str
    String.new('lambda' + Random.rand(100).to_s)
  end

  def pipe_str
    String.new('pipe' + Random.rand(100).to_s)
  end

  def composition_hash(*executables)
    construct_hash = []
    executables.each do |executable|
      case executable.class.name
      when 'Gilmour::Request'
        construct_hash.push(request_str => executable.req_hash)
      when 'Gilmour::Parallel'
        construct_hash.push(parallel_str => executable.parallel_hash['parallel'])
      when 'Gilmour::Lambda'
        construct_hash.push('lambda' => executable.lambda_hash['lambda'])
      when 'Gilmour::Pipe'
        construct_hash.push(pipe_str => executable.pipe_hash['pipe'])
      end
    end
    construct_hash
  end

  def send_http_req(req_url, body)
    sock = Net::BufferedIO.new(UNIXSocket.new(nesting.publish_socket))
    req = Net::HTTP::Post.new(URI('http://127.0.0.1:8080'),
                              'Content-Type' => 'application/json')
    req.body = body
    req.exec(sock, '1.1', req_url)
    begin
      response = Net::HTTPResponse.read_new(sock)
    end while response.is_a?(Net::HTTPContinue)
    response.reading_body(sock, req.response_body_permitted?) {}
    response
  rescue StandardError => e
    puts "Error: #{e.message}"
  end

  def format_data(data, topic, opts)
    {
      topic: topic,
      message: data,
      opts: opts
    }.to_json
  end

  def format_composition_data(data, composition)
    {
      data: data,
      composition: composition
    }.to_json
  end
end
