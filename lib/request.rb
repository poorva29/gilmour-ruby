require_relative 'common'

module Gilmour
  class Request
    include Common
    attr_reader :topic, :timeout, :nesting, :data

    def initialize(topic, opts = nil)
      @topic = topic
      unless opts.nil?
        timeout = opts.timeout
        @timeout = timeout if timeout
      end
      @nesting = Module.nesting.last
    end

    def with(req_data)
      @data = req_data
      self
    end

    def execute!(req_data)
      @data = data.nil? ? req_data : data.merge(req_data)
      request(timeout: timeout)
    end

    def request(opts = {})
      req_url = 'unix://127.0.0.1/request/' + nesting.id
      body = format_data(data, topic, opts)
      response = send_http_req(req_url, body)
      Response.new(response.body, response.code)
    end

    def req_hash
      { topic => data || '' }
    end
  end
end
