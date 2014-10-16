module Her
  class Collection
    def load_all_meta
      klass = a.first.class
      return unless klass.respond_to?(:id_and_buckets)
      id_attributes = klass.id_and_buckets.collect{|h| h[:id]}
      id_attributes.each do |attribute|
        id_attribute_values = self.collect(&attribute.to_sym)
        klass.mmemoized(attribute, id_attribute_values)
      end
    end
  end
end