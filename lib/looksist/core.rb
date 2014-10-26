module Looksist
  module Core
    extend ActiveSupport::Concern
    include Looksist::Common

    module ClassMethods
      def lookup(what, using, bucket = using)
        if what.is_a? Array
          setup_composite_lookup(bucket, using, what)
        else
          self.lookup_attributes << what.to_sym
          define_method(what) do
            Looksist.redis_service.send("#{__entity__(bucket)}_for", self.send(using).try(:to_s))
          end
        end
      end

      private
      def setup_composite_lookup(bucket, using, what)
        what.each do |method_name|
          define_method(method_name) do
            JSON.parse(Looksist.redis_service.send("#{__entity__(bucket)}_for", self.send(using).try(:to_s)) || '{}')[method_name.to_s]
          end
          self.lookup_attributes << method_name
        end
      end
    end

    def as_json(opts)
      Looksist.driver.json_opts(self, opts)
    end

    included do |base|
      base.class_attribute :lookup_attributes
      base.lookup_attributes = []
    end

  end

  module Serializers
    class Her
      class << self
        def json_opts(obj, _)
          obj.attributes.merge(obj.class.lookup_attributes.each_with_object({}) { |a, acc| acc[a] = obj.send(a) })
        end
      end
    end
  end
end