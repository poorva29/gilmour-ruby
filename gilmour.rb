require 'json'
require 'net/http'
require 'socket'
require 'rest-client'
require 'sinatra'
require 'sinatra/base'
require 'thin'
require_relative 'request'
require_relative 'responder'

class App < Sinatra::Base
  attr_reader :req, :resp
  @handler_map = {}

  def initialize
    super
    @req = Request.new
    @resp = Response.new
  end

  class << self
    attr_reader :handler_map

    def set_handler_map(key, value)
      @handler_map[key] = value
    end
  end

  post '/' do
    content_type :json
    request.body.rewind
    info = JSON.parse request.body.read
    path = info['handler_path']
    handlers = self.class.handler_map
    req.data = info['data']
    proc = handlers[path.to_sym]
    proc.call(req, resp)
    resp.data.to_json
  end

  get '/health_check' do
    'I am alive!'
  end
end

class Gilmour
  attr_reader :url, :id, :publish_socket, :thin_server

  def initialize
    @url = 'http://127.0.0.1:8080'
    @thin_server = Thin::Server.new('/tmp/listen_socket.sock', App)
    @thin_server.pid_file = '/tmp/thin.pid'
    @thin_server.log_file = '/tmp/thin.log'
    Thread.new do
      @thin_server.silent = true
      @thin_server.start
    end
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
    req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    req.body = body
    req.exec(sock, '1.1', req_url)
    begin
      response = Net::HTTPResponse.read_new(sock)
    end while response.is_a?(Net::HTTPContinue)
    response.reading_body(sock, req.response_body_permitted?) {}
    response
  end

  def get_handler_path(topic)
    (topic + '_handler').to_sym
  end

  def format_data(data, topic, opts)
    message = {
      data: data,
      handler_path: get_handler_path(topic)
    }
    { topic: topic, message: message, opts: opts }.to_json
  end

  def request!(data, topic, opts = {})
    req_url = 'unix://127.0.0.1/request/' + id
    body = format_data(data, topic, opts)
    response = send_http_req(req_url, body)
    yield(response.body, response.code)
  end

  def signal!(data, topic, opts = {})
    req_url = 'unix://127.0.0.1/signal/' + id
    body = format_data(data, topic, opts)
    send_http_req(req_url, body)
  end

  def create_handler(topic, &handler)
    handler_path = (topic + '_handler').to_sym
    App.set_handler_map(handler_path, handler)
    handler_path
  end

  def reply_to(topic, opts = {}, &handler)
    data = {
      topic.to_s => {
        group: opts[:excl_group],
        path: create_handler(topic, &handler),
        timeout: opts[:timeout]
      }
    }
    RestClient.post url + '/nodes/' + id + '/services',
                    data.to_json, content_type: :json, accept: :json
    # parse body to check if request was successfull else retry
  end

  def slot(topic, opts = {}, &handler)
    data = {
      topic: topic,
      group: opts[:excl_group],
      path: create_handler(topic, &handler),
      timeout: opts[:timeout]
    }
    RestClient.post url + '/nodes/' + id + '/slots',
                    data.to_json, content_type: :json, accept: :json
    # parse body to check if request was successfull else retry
  end

  def stop
    @thin_server.stop
  end
end
