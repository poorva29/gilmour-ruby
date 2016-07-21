module Common
  def get_handler_path(topic)
    (topic + '_handler').to_sym
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
  end

  def format_data(data, topic, opts)
    message = {
      data: data,
      handler_path: get_handler_path(topic)
    }
    { topic: topic, message: message, opts: opts }.to_json
  end
end
