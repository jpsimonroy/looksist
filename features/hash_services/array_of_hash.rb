class ArrayOfHash
  include Looksist

  def menu
    [{
         item_id: 1
    }, {
        item_id: 2
    }, {
        item_id: 3
    }
    ]
  end

  inject after: :menu, using: :item_id, populate: :item_name
end