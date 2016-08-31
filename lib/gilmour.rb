require 'json'
require 'net/http'
require 'socket'
require 'rest-client'
require 'sinatra'
require 'sinatra/base'
require 'thin'
require_relative 'composition_andand'
require_relative 'composition_batch'
require_relative 'composition_oror'
require_relative 'composition_lambda'
require_relative 'composition_pipe'
require_relative 'composition_parallel'
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
    rescue StandardError => e
      nesting.publish_socket = ''
      nesting.id = @id = ''
      puts "Error initializing node: #{e.message}"
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

    def reply_to(topic, opts = nil, &handler)
      data = {
        topic.to_s => {
          path: create_handler(topic, &handler)
        }
      }
      unless opts.nil?
        data[topic.to_s][:group] = opts.excl_group
        data[topic.to_s][:timeout] = opts.timeout
      end
      RestClient.post url + '/nodes/services',
                      data.to_json, content_type: :json, accept: :json,
                                    Authorization: id
    rescue StandardError => e
      puts "Error subscribing service: #{e.message}"
    end

    def unsubscribe_reply(topic)
      RestClient.delete url + "/nodes/services?topic=#{topic}",
                        accept: :json, Authorization: id
    rescue StandardError => e
      puts "Error unsubscribing service: #{e.message}"
    end

    def subscribed_services
      resp = RestClient.get url + '/nodes/services',
                            accept: :json, Authorization: id
      JSON.parse(resp)
    rescue StandardError => e
      puts "Error fetching services: #{e.message}"
    end

    def slot(topic, opts = nil, &handler)
      data = {
        topic: topic,
        path: create_handler(topic, &handler)
      }
      unless opts.nil?
        data[:group] = opts.excl_group
        data[:timeout] = opts.timeout
      end
      RestClient.post url + '/nodes/slots',
                      data.to_json, content_type: :json, accept: :json,
                                    Authorization: id
    rescue StandardError => e
      puts "Error subscribing slot: #{e.message}"
    end

    def unsubscribe_slot(topic)
      RestClient.delete url + "/nodes/slots?topic=#{topic}",
                        accept: :json, Authorization: id
    rescue StandardError => e
      puts "Error unsubscribing slot: #{e.message}"
    end

    def subscribed_slots
      resp = RestClient.get url + '/nodes/slots',
                            accept: :json, Authorization: id
      JSON.parse(resp)
    rescue StandardError => e
      puts "Error fetching slots: #{e.message}"
    end

    def stop
      @thin_server.stop
      RestClient.delete url + '/nodes', Authorization: id
    rescue StandardError => e
      puts "Error stopping server: #{e.message}"
    end
  end
end
