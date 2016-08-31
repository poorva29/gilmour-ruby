require_relative 'common'

module Gilmour
  class AndAnd
    include Common
    attr_reader :andand_hash, :data, :nesting

    def initialize(*executables)
      @nesting = Module.nesting.last
      @andand_hash = { 'andand' => composition_hash(*executables) }
    end

    def request
      req_url = 'unix://127.0.0.1/composition/' + nesting.id
      body = format_composition_data(data, andand_hash)
      response = send_http_req(req_url, body)
      Response.new(response.body, response.code)
    end

    def execute!(req_data = nil)
      @data = data.nil? ? req_data : data.merge(req_data)
      request
    end
  end
end
