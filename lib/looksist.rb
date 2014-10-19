require 'looksist/version'
require 'jsonpath'
require 'json'
require 'looksist/core'
require 'looksist/redis_service'
require 'looksist/hashed'
require 'looksist/her_collection'
require 'looksist/safe_lru_cache'


module Looksist

  extend ActiveSupport::Concern

  include Core
  include Hashed

  class << self
    attr_accessor :lookup_store, :driver, :cache_buffer_size, :redis_service

    def configure
      yield self
      self.redis_service = Looksist::RedisService.instance do |lookup|
        lookup.client = self.lookup_store
        lookup.buffer_size = self.cache_buffer_size || 50000
      end
    end

  end

end