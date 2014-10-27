module Looksist
  class RedisService

    attr_accessor :client, :buffer_size, :cache

    class << self
      private :new

      def instance
        @this ||= new
        @this.buffer_size = 50000
        yield @this if block_given?
        @this.cache = SafeLruCache.new(@this.buffer_size)
        @this
      end
    end

    def method_missing(name, *args, &block)
      if name.to_s.ends_with?('_for')
        entity = name.to_s.gsub('_for', '')
        first_arg = args.first
        first_arg.is_a?(Array) ? find_all(entity, first_arg) : find(entity, first_arg)
      else
        super(name, args)
      end
    end

    def flush_cache!
      @cache.clear
    end

    private

    def find_all(entity, ids)
      raise 'Buffer overflow! Increase buffer size' if  ids.length > @buffer_size && @buffer_size != 0
      keys = ids.collect { |id| redis_key(entity, id) }
      missed_keys = cache_op(proc_from { keys.uniq }) { (keys - @cache.keys).uniq }
      unless missed_keys.empty?
        response = Hash[*missed_keys.zip(@client.mget *missed_keys).flatten]
        cache_op { @cache.merge!(response) }
      end
      (cache_op(proc_from { keys.collect {|k| response[k] } }) { @cache.mslice(keys) })
    end

    def cache_op(computed = nil)
      if @buffer_size == 0
        return computed.call if computed
      else
        yield
      end
    end

    def find(entity, id)
      key = redis_key(entity, id)
      fetch(key) do
        @client.get(key)
      end
    end

    def fetch(key, &block)
      (cache_op(proc_from { block.call }) { @cache[key] ||= block.call })
    end

    def redis_key(entity, id)
      "#{entity.pluralize}/#{id}"
    end

    def proc_from
      Proc.new
    end
  end
end
