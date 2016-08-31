require_relative 'common'

module Gilmour
  class Lambda
    include Common
    attr_reader :lambda_hash, :data, :nesting, :func_name

    def create_handler
      handler_path = (func_name.to_s + '_handler').to_sym
      App.set_handler_map(handler_path, method(func_name))
      handler_path
    end

    def initialize(func_name)
      @func_name = func_name.to_sym
      path = create_handler
      @lambda_hash = { 'lambda' => path }
      @nesting = Module.nesting.last
    end

    def request
      req_url = 'unix://127.0.0.1/composition/' + nesting.id
      body = format_composition_data(data, lambda_hash)
      response = send_http_req(req_url, body)
      Response.new(response.body, response.code)
    end

    def execute!(req_data = nil)
      @data = data.nil? ? req_data : data.merge(req_data)
      request
    end
  end
end
