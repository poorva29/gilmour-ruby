module Gilmour
  class RequestOpts
    attr_reader :timeout
    def initialize(opts = {})
      timeout = opts[:timeout]
      @timeout = timeout unless timeout.nil?
    end
  end
end
