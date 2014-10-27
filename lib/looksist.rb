require 'looksist/version'
require 'jsonpath'
require 'looksist/common'
require 'looksist/core'
require 'looksist/redis_service'
require 'looksist/hashed'
require 'looksist/safe_lru_cache'


module Looksist

  extend ActiveSupport::Concern

  include Core
  include Hashed

  class << self
    attr_accessor :lookup_store, :driver, :cache_buffer_size, :redis_service, :l2_cache

    def configure
      yield self
      self.redis_service = Looksist::RedisService.instance do |lookup|
        lookup.client = self.lookup_store
        lookup.buffer_size = (self.l2_cache == :no_cache) ? 0 : (self.cache_buffer_size || 50000)
      end
    end

    def bucket_dump(entity)
      keys = Looksist.lookup_store.keys("#{entity.pluralize}*")
      values = Looksist.redis_service.send("#{entity}_for", keys.collect{|i| i.split('/').last})
      (keys.collect {|i| i.split('/').last}).zip(values).to_h
    end
  end
end