require_relative 'common'

module Gilmour
  class Request
    include Common
    attr_reader :topic, :timeout, :nesting

    def initialize(topic, opts = nil)
      @topic = topic
      unless opts.nil?
        timeout = opts.timeout
        @timeout = timeout if timeout
      end
      @nesting = Module.nesting.last
    end

    def execute!(data)
      request(data, topic, timeout: timeout)
    end

    def request(data, topic, opts = {})
      req_url = 'unix://127.0.0.1/request/' + nesting.id
      body = format_data(data, topic, opts)
      response = send_http_req(req_url, body)
      Response.new(response.body, response.code)
    end
  end
end
