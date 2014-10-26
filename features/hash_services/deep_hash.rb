class DeepHash
  include Looksist

  def metrics
    {
        table: {
            inner_table: {
                employee_id: [10, 20]
            }
        }
    }
  end

  inject after: :metrics, at: '$.table.inner_table', using: :employee_id, populate: :employee_name
end