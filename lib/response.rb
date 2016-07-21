module Gilmour
  class Response
    attr_reader :code, :data

    def initialize(body, code)
      @data = body
      @code = code
    end
  end
end
