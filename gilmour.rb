require 'json'
require 'net/http'
require 'socket'
require 'rest-client'

class Gilmour
  attr_reader :url, :id, :publish_socket

  def initialize
    @url = 'http://127.0.0.1:8080'
    add_node
  end

  def uri
    URI(url)
  end

  def add_node
    node = {
      listen_sock: '/tmp/listen_socket.sock',
      health_check: '/health_check',
      services: {}, slots: []
    }
    response = RestClient.put url + '/nodes', node.to_json,
                              content_type: :json, accept: :json
    node_details = JSON.parse(response.body)
    @publish_socket = node_details['publish_socket']
    @id = node_details['id']
  end

  def send_http_req(req_url, body)
    sock = Net::BufferedIO.new(UNIXSocket.new(publish_socket))
    req = Net::HTTP::Post.new(uri, { 'Content-Type' => 'application/json' })
    req.body = body
    req.exec(sock, '1.1', req_url)
    begin
      response = Net::HTTPResponse.read_new(sock)
    end while response.is_a?(Net::HTTPContinue)
    response.reading_body(sock, req.response_body_permitted?) {}
    response
  end

  def request!(message, topic, opts = {})
    req_url = 'unix://127.0.0.1/request/' + id
    body = { topic: topic, message: message, opts: opts }.to_json
    response = send_http_req(req_url, body)
    yield(response.body, response.code)
  end

  def signal!(message, topic, opts = {})
    req_url = 'unix://127.0.0.1/signal/' + id
    body = { topic: topic, message: message, opts: opts }.to_json
    send_http_req(req_url, body)
  end

  def create_handler(&handler)
    # Create method for handler and add it to node_map
    '/handler_path'
  end

  def reply_to(topic, opts = {}, &handler)
    data = {
      topic.to_s => {
        group: opts[:excl_group],
        path: create_handler(&handler),
        timeout: opts[:timeout],
        data: opts[:data] || ''
      }
    }
    response = RestClient.post url + '/nodes/' + id + '/services',
                               data.to_json, content_type: :json, accept: :json
    puts JSON.parse(response.body)
  end

  def slot(topic, opts = {}, &handler)
    data = {
      topic: topic,
      group: opts[:excl_group],
      path: create_handler(&handler),
      timeout: opts[:timeout],
      data: opts[:data] || ''
    }
    response = RestClient.post url + '/nodes/' + id + '/slots',
                               data.to_json, content_type: :json, accept: :json
    puts JSON.parse(response.body)
  end
end
