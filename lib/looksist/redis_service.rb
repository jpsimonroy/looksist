module Looksist
  class RedisService
    attr_accessor :client, :buffer_size, :cache

    def self.instance
      @_instance_ ||= new
      @_instance_.cache ||= {}
      yield @_instance_ if block_given?
      @_instance_.buffer_size ||= 50000
      @_instance_
    end

    def method_missing(m, *args, &block)
      if m.to_s.ends_with?("_for")
        entity = m.to_s.gsub('_for', '')
        args.first.is_a?(Array) ? find_all(entity, args.first) : find(entity, args.first)
      else
        super(m, args)
      end
    end

    private

    def find(entity, id)
      key = redis_key(entity, id)
      hit_or_miss(key) do
        @client.get(key)
      end
    end


    def find_all(entity, ids)
      @client.pipelined do
        ids.uniq.each do |id|
          find(entity, id)
        end
      end
      ids.each_with_object([]) { |k, acc| acc << cache[redis_key(entity, k)].value }
    end

    def hit_or_miss(key, &block)
      @cache[key] ||= lru(&block)
    end

    def lru
      @cache.shift if @cache.length >= @buffer_size
      yield
    end

    def redis_key(entity, id)
      "#{entity.pluralize}/#{id}"
    end
  end
end
