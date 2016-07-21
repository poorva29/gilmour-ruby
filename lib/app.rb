module Gilmour
  class App < Sinatra::Base
    attr_reader :req, :resp

    @handler_map = {}

    def initialize
      super
      @req = HandlerReq.new
      @resp = HandlerResp.new
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
end
