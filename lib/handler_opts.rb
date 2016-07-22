module Gilmour
  class HandlerOpts
    attr_reader :timeout, :excl_group
    def initialize(opts = {})
      @timeout = opts[:timeout] if opts[:timeout]
      @excl_group = opts[:excl_group] if opts[:excl_group]
    end
  end
end
