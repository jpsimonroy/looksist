class Menu
  include Looksist

  def menu
    {
        table: {
            menu: [
                {
                    item_id: 1
                },
                {
                    item_id: 2
                }
            ]
        }
    }
  end

  inject after: :menu, at: '$.table.menu', using: :item_id, populate: :item_name
end