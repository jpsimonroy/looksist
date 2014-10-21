module Looksist
  module Common
    # Careful with the method names, these become instance variables!!
    def __entity__(entity)
      entity.to_s.gsub('_id', '')
    end
  end
end