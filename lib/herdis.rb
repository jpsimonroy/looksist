require 'herdis/version'

module Herdis
  extend ActiveSupport::Concern
  class << self;
    attr_accessor :lookup_store_client
  end

  module ClassMethods

    def bucket_name(entity_id)
      entity = entity_id.to_s.gsub('_id', '')
      entity.pluralize
    end

    def lookup(what, using, bucket = bucket_name(using))
      self.lookup_attributes ||= []
      if what.is_a? Array
        what.each do |method_name|
          define_method(method_name) do
            key = [bucket, '/', self[using].try(:to_s)].join('')
            JSON.parse(send(:memoized, key))[method_name.to_s]
          end
          self.lookup_attributes << method_name
        end
      else
        define_method(what) do
          key = [bucket, '/', self[using].try(:to_s)].join('')
          send(:memoized, key)
        end
        self.lookup_attributes << what.to_sym
      end
    end
  end

  included do |base|
    base.class_attribute :lookup_attributes
  end

  def as_json(opts = {})
    self.class.lookup_attributes ||= []
    attributes.merge(self.class.lookup_attributes.each_with_object({}) { |a, acc| acc[a] = send(a) })
  end

  private

  def memoized(key)
    @storage = @storage || OpenStruct.new
    @storage[key] = @storage[key] || Herdis.lookup_store_client.get(key)
  end
end
