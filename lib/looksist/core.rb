module Looksist
  module Core
    extend ActiveSupport::Concern
    include Looksist::Common

    module ClassMethods

      attr_accessor :lookup_attributes

      def lookup(what, opts)
        @lookup_attributes ||= {}
        unless opts.keys.all? { |k| [:using, :bucket_name, :as].include? k }
          raise 'Incorrect usage: Invalid parameter specified'
        end
        using, bucket_name, as = opts[:using], opts[:bucket_name] || opts[:using], opts[:as]
        if what.is_a? Array
          setup_composite_lookup(bucket_name, using, what, as)
        else
          alias_what = find_alias(as, what)
          @lookup_attributes[alias_what] = opts[:using]
          define_method(alias_what) do
            Looksist.redis_service.send("#{__entity__(bucket_name)}_for", self.send(using).try(:to_s))
          end
        end
      end

      private
      def setup_composite_lookup(bucket, using, what, as)
        what.each do |method_name|
          alias_method_name = find_alias(as, method_name)
          define_method(alias_method_name) do
            JSON.parse(Looksist.redis_service.send("#{__entity__(bucket)}_for", self.send(using).try(:to_s)) || '{}')[method_name.to_s]
          end
          @lookup_attributes[alias_method_name] = using
        end
      end

      def find_alias(as_map, what)
        (as_map and as_map.has_key?(what)) ? as_map[what].to_sym : what
      end
    end


    def as_json(opts)
      parent_lookups = {}
      class_lookups = self.class.lookup_attributes || {}
      if self.class.superclass.respond_to?(:lookup_attributes)
        parent_lookups = self.class.superclass.lookup_attributes || {}
      end
      Looksist.driver.json_opts(self, class_lookups.merge(parent_lookups), opts)
    end

  end

  module Serializers
    class Her
      class << self
        def json_opts(obj, lookup_attributes, _)
          lookup_attributes ||= {}
          other_attributes = lookup_attributes.keys.each_with_object({}) do |a, acc|
            using = lookup_attributes[a]
            acc[a] = obj.send(a) if obj.respond_to?(using)
          end
          obj.attributes.merge(other_attributes)
        end
      end
    end
  end
end