require 'active_support/all'
require 'faraday_middleware'
require 'her'
require 'ostruct'
require 'looksist'
require 'looksist/redis_service'
require 'looksist/hashed'
require 'looksist/safe_lru_cache'
require 'pry'
require 'redis'
require 'hiredis'
require 'jsonpath'

I18n.enforce_available_locales = false

Looksist.configure do |looksist|
  looksist.lookup_store = Redis.new(url: 'redis://localhost:6379', driver: :hiredis)
  looksist.driver = Looksist::Serializers::Her
end