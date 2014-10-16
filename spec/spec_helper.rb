require 'active_support/all'
require 'faraday_middleware'
require 'her'
require 'ostruct'
require 'looksist'
require 'looksist/redis_service'
require 'looksist/hashed'
require 'pry'

module Her
  module Model
    def as_json(opts={})
      attributes
    end
  end
end

TEST_API = Her::API.new

config = Proc.new do |conn|
  conn.use FaradayMiddleware::EncodeJson
  conn.use Faraday::Request::UrlEncoded
  conn.use Her::Middleware::DefaultParseJSON
  conn.use Faraday::Adapter::NetHttp
  conn.use Faraday::Response::RaiseError
end

TEST_API.setup url: 'http://dummy.com', &config

