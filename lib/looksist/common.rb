module Looksist
  module Common
    def entity(entity)
      entity.to_s.gsub('_id', '')
    end
  end
end