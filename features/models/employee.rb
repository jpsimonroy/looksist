class Employee
  include Looksist
  attr_accessor :employee_id
  lookup :name, using: :employee_id

  def initialize(id)
    @employee_id = id
  end
end