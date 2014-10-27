require 'active_support/all'
require 'faraday_middleware'
require 'her'
require 'ostruct'
require 'pry'
require 'redis'
require 'hiredis'
require 'jsonpath'
require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
]

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/features/'
end

require 'looksist'
require 'looksist/redis_service'
require 'looksist/hashed'
require 'looksist/safe_lru_cache'


I18n.enforce_available_locales = false

Looksist.configure do |looksist|
  looksist.lookup_store = Redis.new(url: 'redis://localhost:6379', driver: :hiredis)
  looksist.l2_cache = :no_cache
  looksist.driver = Looksist::Serializers::Her
end
