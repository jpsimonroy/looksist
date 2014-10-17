require 'jsonpath'
require 'json'

module Looksist
  module Hashed
    extend ActiveSupport::Concern

    class << self;
      attr_accessor :redis_service
    end

    module ClassMethods
      def inject(opts)
        raise 'Incorrect usage' unless [:after, :using, :populate].all? { |e| opts.keys.include? e }

        after = opts[:after]
        @rules ||= {}
        (@rules[after] ||= []) << opts

        return if @rules[after].length > 1

        define_method("#{after}_with_inject") do |*args|
          hash = send("#{after}_without_inject".to_sym, *args)
          self.class.instance_variable_get(:@rules)[after].each do |opts|
            if opts[:at].is_a? String
              hash = JsonPath.for(hash.with_indifferent_access).gsub(opts[:at]) do |i|
                i.is_a?(Array) ? inject_attributes_for(i, opts) : inject_attributes_at(i, opts)
              end.to_hash.deep_symbolize_keys
            else
              inject_attributes_at(hash[opts[:at]], opts)
            end
          end
          hash
        end
        alias_method_chain after, :inject

      end
    end

    included do |base|
      base.class_attribute :rules
    end

    private
    def entity(entity_id)
      entity_id.to_s.gsub('_id', '')
    end

    def inject_attributes_at(hash_offset, opts)
      keys = hash_offset[opts[:using]]
      entity_name = entity(opts[:using])
      values = Hashed.redis_service.send("#{entity_name}_for", keys)
      hash_offset[opts[:populate]] = values
      hash_offset
    end

    def inject_attributes_for(arry_of_hashes, opts)
      arry_of_hashes.each do |elt|
        key = elt[opts[:using]]
        entity_name = entity(opts[:using])
        value = Hashed.redis_service.send("#{entity_name}_for", [key])
        elt[opts[:populate]] = value.first
      end
    end
  end
end
