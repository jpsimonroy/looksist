module Looksist
  module Hashed
    extend ActiveSupport::Concern

    # inject after: :assortment, at: 'table', using: :supplier_id, populate: :supplier_name, bucket_name: 'suppliers'

    class << self;
      attr_accessor :redis_service
    end

    module ClassMethods
      def inject(opts)
        raise 'Incorrect usage' unless [:after, :using, :populate].all? { |e| opts.keys.include? e }
        @rules ||= {}
        @rules[opts[:after]] ||= []
        @rules[opts[:after]] << opts

        return if @rules[opts[:after]].length > 1

        define_method("#{opts[:after]}_with_inject") do |*args|
          hash = send("#{opts[:after]}_without_inject".to_sym, *args)
          self.class.instance_variable_get(:@rules)[opts[:after]].each do |opts|
            keys = hash[opts[:at]][opts[:using]]
            entity_name = entity(opts[:using])
            values = Hashed.redis_service.send("#{entity_name}_for", keys)
            hash[opts[:at]][opts[:populate]] = values
          end
          hash
        end

        alias_method_chain opts[:after], :inject
      end
    end

    included do |base|
      base.class_attribute :rules
    end

    def entity(entity_id)
      entity = entity_id.to_s.gsub('_id', '')
    end
  end
end
