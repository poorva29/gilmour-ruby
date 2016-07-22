module Gilmour
  class RequestOpts
    attr_reader :timeout
    def initialize(opts = {})
      @timeout = opts[:timeout] if opts[:timeout]
    end
  end
end
