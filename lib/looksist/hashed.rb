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
          if self.singleton_methods.include?(after)
            inject_class_methods(after)
          else
            inject_instance_methods(after)
          end
        end
      end

      def inject_instance_methods(after)
        define_method("#{after}_with_inject") do |*args|
          hash = send("#{after}_without_inject".to_sym, *args)
          rules_group_by_at = self.class.instance_variable_get(:@rules)[after].group_by { |e| e[:at] }
          rules_group_by_at.each do |at, opts|
            if at.nil? or at.is_a? String
              hash = self.class.update_using_json_path(hash, at, opts)
            else
              self.class.inject_attributes_at(hash[at], opts)
            end
          end
          hash
        end
        alias_method_chain after, :inject
      end

      def inject_class_methods(after)
        define_singleton_method("#{after}_with_inject") do |*args|
          hash = send("#{after}_without_inject".to_sym, *args)
          rules_group_by_at = @rules[after].group_by { |e| e[:at] }
          rules_group_by_at.each do |at, opts|
            if at.nil? or at.is_a? String
              hash = update_using_json_path(hash, at, opts)
            else
              inject_attributes_at(hash[at], opts)
            end
          end
          hash
        end
        self.singleton_class.send(:alias_method_chain, after, :inject)
      end

      def inject_attributes_at(hash_offset, opts)
        return hash_offset if hash_offset.nil? or hash_offset.empty?
        opts.each do |opt|
          keys = hash_offset[opt[:using]]
          entity_name = __entity__(opt[:bucket_name] || opt[:using])
          values = Looksist.redis_service.send("#{entity_name}_for", keys)
          if opt[:populate].is_a? Array
            opt[:populate].each do |elt|
              if values.is_a?(Array)
                value_hash = values.each_with_object([]) do |i, acc|
                  acc << JSON.parse(i || '{}').deep_symbolize_keys[elt]
                end
              else
                value_hash = JSON.parse(values || '{}').deep_symbolize_keys[elt]
              end
              alias_method = find_alias(opt[:as], elt)
              hash_offset[alias_method] = value_hash
            end
          else
            alias_method = find_alias(opt[:as], opt[:populate])
            hash_offset[alias_method] = values
          end
        end
        hash_offset
      end

      def update_using_json_path(hash, at, opts)
        if hash.is_a?(Hash)
          if at.present?
            JsonPath.for(hash.with_indifferent_access).gsub!(at) do |i|
              i.is_a?(Array) ? inject_attributes_for(i, at, opts) : inject_attributes_at(i, opts) unless (i.nil? or i.empty?)
              i
            end
          else
            inject_attributes_at(hash, opts)
          end.to_hash.deep_symbolize_keys
        else
          inject_attributes_for_array(hash, at, opts)
        end
      end

      def inject_attributes_for(array_of_hashes, at, opts)
        all_values = opts.each_with_object({}) do |opt, acc|
          entity_name = __entity__(opt[:bucket_name] || opt[:using])
          keys = (array_of_hashes.collect { |i| i[opt[:using]] }).compact.uniq
          values = Hash[keys.zip(Looksist.redis_service.send("#{entity_name}_for", keys))]
          acc[opt[:using]] = values
        end
        smart_lookup(array_of_hashes, opts, all_values, nil)
      end

      def inject_attributes_for_array(array_of_hashes, at, opts)
        all_values = opts.each_with_object({}) do |opt, acc|
          entity_name = __entity__(opt[:bucket_name] || opt[:using])
          modified_array = extract_values(array_of_hashes, opt[:using])
          keys = modified_array.flatten.compact.uniq
          values = Hash[keys.zip(Looksist.redis_service.send("#{entity_name}_for", keys))]
          acc[opt[:using]] = values
        end
        smart_lookup(array_of_hashes, opts, all_values, at)
      end

      def extract_values(array_of_hashes, using)
        hash = array_of_hashes.is_a?(Array) ? {:root => array_of_hashes} : array_of_hashes
        hash.find_all_values_for(using)
      end

      def smart_lookup(array_of_hashes, opts, all_values, at)
        ## populate is not a array
        array_of_hashes.collect do |elt|
          if at.present?
            JsonPath.for(elt.with_indifferent_access).gsub!(at) do |node|
              if node.is_a? Array
                node.each do |x|
                  opts.each do |opt|
                    values = all_values[opt[:using]]
                    do_populate(x, values, opt[:using], opt[:as], opt[:populate])
                  end
                end
              else
                opts.each do |opt|
                  values = all_values[opt[:using]]
                  do_populate(node, values, opt[:using], opt[:as], opt[:populate])
                end
              end
              node
            end.to_hash.deep_symbolize_keys
          else
            opts.each do |opt|
              values = all_values[opt[:using]]
              do_populate(elt, values, opt[:using], opt[:as], opt[:populate])
            end
            elt
          end
        end
      end

      def do_populate(elt, values, using, as, populate)
        if populate.is_a? Array
          populate.collect do |_key|
            alias_method = find_alias(as, _key)
            parsed_key = JSON.parse(values[elt.with_indifferent_access[using]] || '{}').deep_symbolize_keys
            elt[alias_method] = parsed_key[_key]
          end
        else
          alias_method = find_alias(as, populate)
          elt[alias_method] = values[elt.with_indifferent_access[using]]
        end
      end


      def __entity__(entity)
        entity.to_s.gsub('_id', '')
      end

    end

    included do |base|
      base.class_attribute :rules
      base.rules = {}
    end


  end
end
