module Looksist
  module Core
    extend ActiveSupport::Concern
    include Looksist::Common

    module ClassMethods
      def lookup(what, using, bucket = using)
        self.lookup_attributes ||= []
        self.id_and_buckets ||= []
        self.id_and_buckets << {id: using, bucket: bucket}
        if what.is_a? Array
          what.each do |method_name|
            define_method(method_name) do
              JSON.parse(Looksist.redis_service.send("#{entity(bucket)}_for", self.send(using).try(:to_s)) || '{}')[method_name.to_s]
            end
            self.lookup_attributes << method_name
          end
        else
          define_method(what) do
            Looksist.redis_service.send("#{entity(bucket)}_for", self.send(using).try(:to_s))
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