require_relative 'common'

module Gilmour
  class Parallel
    include Common
    attr_reader :parallel_hash, :data, :nesting

    def initialize(*executables)
      @nesting = Module.nesting.last
      @parallel_hash = { 'parallel' => composition_hash(*executables) }
    end

    def request
      req_url = 'unix://127.0.0.1/composition/' + nesting.id
      body = format_composition_data(data, parallel_hash)
      response = send_http_req(req_url, body)
      Response.new(response.body, response.code)
    end

    def execute!(req_data = nil)
      @data = data.nil? ? req_data : data.merge(req_data)
      request
    end
  end
end
