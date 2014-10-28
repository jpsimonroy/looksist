require 'active_support/all'
require 'her'
require 'faraday'
require 'ostruct'
require 'pry'
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

module Her
  module Model
    def as_json(opts={})
      attributes
    end
  end
end

TEST_API = Her::API.new

config = Proc.new do |conn|
  conn.use Her::Middleware::DefaultParseJSON
  conn.use Faraday::Adapter::NetHttp
  conn.use Faraday::Response::RaiseError
end

TEST_API.setup url: 'http://dummy.com', &config

RSpec.configure do |config|

end
