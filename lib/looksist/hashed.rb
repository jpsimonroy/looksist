require 'jsonpath'
require 'json'

module Looksist
  module Hashed
    extend ActiveSupport::Concern
    include Looksist::Common

    module ClassMethods
      def inject(opts)
        raise 'Incorrect usage' unless [:after, :using, :populate].all? { |e| opts.keys.include? e }

        after = opts[:after]
        @rules ||= {}
        (@rules[after] ||= []) << opts

        unless @rules[after].length > 1
          define_method("#{after}_with_inject") do |*args|
            hash = send("#{after}_without_inject".to_sym, *args)
            self.class.instance_variable_get(:@rules)[after].each do |opts|
              if opts[:at].is_a? String
                hash = update_using_json_path(hash, opts).to_hash.deep_symbolize_keys
              else
                inject_attributes_at(hash[opts[:at]], opts)
              end
            end
            hash
          end
          alias_method_chain after, :inject
        end
      end


    end

    included do |base|
      base.class_attribute :rules
      base.rules = {}
    end

    private

    def inject_attributes_at(hash_offset, opts)
      return hash_offset if hash_offset.nil? or hash_offset.empty?
      keys = hash_offset[opts[:using]]
      entity_name = __entity__(opts[:bucket_name] || opts[:using])
      values = Looksist.redis_service.send("#{entity_name}_for", keys)
      hash_offset[opts[:populate]] = values
      hash_offset
    end

    def update_using_json_path(hash, opts)
      JsonPath.for(hash.with_indifferent_access).gsub!(opts[:at]) do |i|
        i.is_a?(Array) ? inject_attributes_for(i, opts) : inject_attributes_at(i, opts) unless i.empty?
        i
      end
    end

    def inject_attributes_for(arry_of_hashes, opts)
      entity_name = __entity__(opts[:bucket_name] || opts[:using])
      keys = (arry_of_hashes.collect { |i| i[opts[:using]] }).compact.uniq
      values = keys.zip(Looksist.redis_service.send("#{entity_name}_for", keys)).to_h
      arry_of_hashes.each do |elt|
        elt[opts[:populate]] = values[elt[opts[:using]]]
      end
    end
  end
end
