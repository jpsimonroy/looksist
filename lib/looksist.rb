require 'looksist/version'
require 'looksist/redis_service'
require 'looksist/hashed'
require 'looksist/her_collection'

module Looksist
  extend ActiveSupport::Concern
  class << self;
    attr_accessor :lookup_store_client, :driver
  end

  module ClassMethods

    def bucket_name(entity_id)
      entity = entity_id.to_s.gsub('_id', '')
      entity.pluralize
    end

    def memoized(key)
      self.storage ||= OpenStruct.new
      self.storage[key] = self.storage[key] || Looksist.lookup_store_client.get(key)
    end

    def mmemoized(key, values)
      key_and_bucket = id_and_buckets.find{|h| h[:id] == key}
      return if key_and_bucket.nil?
      redis_keys = values.collect{|v| redis_key(key_and_bucket[:bucket], v)}
      left_keys_to_lookup = redis_keys.select{|k| self.storage[k].nil?}
      Looksist.lookup_store_client.mapped_mget(left_keys_to_lookup).each do |key, value|
        self.storage[key] = value
      end

    end

    def redis_key bucket, value
      [bucket, '/', value].join('')
    end

    def lookup(what, using, bucket = bucket_name(using))
      self.lookup_attributes ||= []
      self.id_and_buckets ||= []
      self.id_and_buckets << {id: using, bucket: bucket}
      if what.is_a? Array
        what.each do |method_name|
          define_method(method_name) do
            JSON.parse(self.class.memoized(self.class.redis_key(bucket, self.send(using).try(:to_s))) || '{}')[method_name.to_s]
          end
          self.lookup_attributes << method_name
        end
      else
        define_method(what) do
          self.class.memoized(self.class.redis_key(bucket, self.send(using).try(:to_s)))
        end
        self.lookup_attributes << what.to_sym
      end
    end
  end



  def as_json(opts)
    Looksist.driver.json_opts(self, opts)
  end

  included do |base|
    base.class_attribute :lookup_attributes, :storage, :id_and_buckets
  end

  module Serializers
    class Her
      class << self
        def json_opts(obj, opts)
          obj.class.lookup_attributes ||= []
          obj.attributes.merge(obj.class.lookup_attributes.each_with_object({}) { |a, acc| acc[a] = obj.send(a) })
        end
      end
    end
  end
end