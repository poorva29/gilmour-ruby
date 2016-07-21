require 'json'
require 'net/http'
require 'socket'
require 'rest-client'
require 'sinatra'
require 'sinatra/base'
require 'thin'
require_relative 'request'
require_relative 'response'
require_relative 'handler_opts'
require_relative 'handler_req'
require_relative 'handler_resp'
require_relative 'request_opts'
require_relative 'app'
require_relative 'common'

module Gilmour
  class << self
    attr_accessor :id, :publish_socket
  end

  def foo
  end

  class Gilmour
    include Common
    attr_reader :url, :id, :thin_server, :nesting

    def initialize
      @nesting = Module.nesting.last
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
      nesting.publish_socket = node_details['publish_socket']
      nesting.id = @id = node_details['id']
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

    def reply_to(topic, opts, &handler)
      data = {
        topic.to_s => {
          group: opts.excl_group,
          path: create_handler(topic, &handler),
          timeout: opts.timeout
        }
      }
      RestClient.post url + '/nodes/' + id + '/services',
                      data.to_json, content_type: :json, accept: :json
      # parse body to check if request was successfull else retry
    end

    def slot(topic, opts, &handler)
      data = {
        topic: topic,
        group: opts.excl_group,
        path: create_handler(topic, &handler),
        timeout: opts.timeout
      }
      RestClient.post url + '/nodes/' + id + '/slots',
                      data.to_json, content_type: :json, accept: :json
      # parse body to check if request was successfull else retry
    end

    def stop
      @thin_server.stop
    end
  end
end