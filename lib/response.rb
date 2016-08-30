require 'json'

module Gilmour
  class Response
    attr_reader :code, :data, :next

    def initialize(body, code)
      @next = body.nil? ? nil : JSON.parse(body)
      @code = code
    end
  end
end
