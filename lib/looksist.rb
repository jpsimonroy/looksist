require 'looksist/version'

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

    def lookup(what, using, bucket = bucket_name(using))
      self.lookup_attributes ||= []
      if what.is_a? Array
        what.each do |method_name|
          define_method(method_name) do
            key = [bucket, '/', self.send(using).try(:to_s)].join('')
            JSON.parse(self.class.memoized(key))[method_name.to_s]
          end
          self.lookup_attributes << method_name
        end
      else
        define_method(what) do
          key = [bucket, '/', self.send(using).try(:to_s)].join('')
          self.class.memoized(key)
        end
        self.lookup_attributes << what.to_sym
      end
    end
  end

  def as_json(opts)
    Looksist.driver.json_opts(self, opts)
  end

  included do |base|
    base.class_attribute :lookup_attributes, :storage
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
