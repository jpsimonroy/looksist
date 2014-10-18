require 'monitor'

module Looksist
  class SafeLruCache < Hash

    include MonitorMixin

    def initialize(max_size)
      @max_size = max_size
      super(nil)
    end

    def []=(key, val)
      synchronize do
        super(key, val)
        pop
        val
      end
    end

    def merge!(hash)
      synchronize do
        super(hash)
        (count - @max_size).times { pop }
      end
    end

    def mslice(keys)
      synchronize do
        keys.collect { |k| self[k] }
      end
    end

    private

    def pop
      # not using shift coz: http://bugs.ruby-lang.org/issues/8312
      delete(first[0]) if count > @max_size
    end

    def self.synchronize(*methods)
      methods.each do |method|
        define_method method do |*args, &blk|
          synchronize do
            super(*args, &blk)
          end
        end
      end
    end

    synchronize :[], :each, :to_a, :delete, :count, :has_key?

  end
end