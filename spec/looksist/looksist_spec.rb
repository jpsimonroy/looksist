require 'spec_helper'


describe Looksist do
  before(:each) do
    @mock = {}
    Looksist.configure do |looksist|
      looksist.lookup_store = @mock
      looksist.driver = Looksist::Serializers::Her
    end
  end

  context 'Serialization Support' do
    it 'should decorate for her models' do
      module Her
        class Employee
          include Her::Model
          use_api TEST_API
          include Looksist

          lookup :name, using = :employee_id

          def as_json(opts)
            super(opts).merge(another_attr: 'Hello World')
          end
        end
      end
      expect(@mock).to receive(:get).once.with('employees/1').and_return('Employee Name')
      e = Her::Employee.new({employee_id: 1})
      expect(e.name).to eq('Employee Name')
      expect(e.to_json).to eq({:employee_id => 1, :name => 'Employee Name', :another_attr => 'Hello World'}.to_json)
    end
  end

  context 'Store Lookup' do
    it 'should consider bucket key when provided' do
      module ExplicitBucket
        class Employee
          include Looksist
          attr_accessor :id
          lookup :name, using = :id, bucket_name = 'employees'

          def initialize(id)
            @id = id
          end
        end
      end
      expect(@mock).to receive(:get).once.with('employees/1').and_return('Employee Name')
      e = ExplicitBucket::Employee.new(1)
      expect(e.name).to eq('Employee Name')
    end
  end

  context 'Lazy Evaluation' do
    module LazyEval
      class HerEmployee
        include Her::Model
        use_api TEST_API
        include Looksist

        lookup :name, using = :employee_id

        def as_json(opts)
          super(opts).merge(another_attr: 'Hello World')
        end
      end
      class Employee
        include Looksist
        attr_accessor :id
        lookup :name, using = :id, bucket_name = 'employees'

        def initialize(id)
          @id = id
        end
      end
    end
    it 'should not eager evaluate' do
      expect(@mock).to_not receive(:get)
      LazyEval::Employee.new(1)
      LazyEval::HerEmployee.new(employee_id: 1)
    end
  end

  context 'lookup attributes' do
    it 'should generate declarative attributes on the model with simple lookup value' do
      module SimpleLookup
        class Employee
          include Looksist
          attr_accessor :id, :employee_id
          lookup :name, using= :id
          lookup :unavailable, using= :employee_id

          def initialize(id)
            @id = @employee_id = id
          end
        end
      end

      expect(@mock).to receive(:get).once.with('ids/1').and_return('Employee Name')
      expect(@mock).to receive(:get).once.with('employees/1').and_return(nil)
      e = SimpleLookup::Employee.new(1)
      expect(e.name).to eq('Employee Name')
      expect(e.unavailable).to be(nil)
    end

    it 'should generate declarative attributes on the model with object based lookup value' do
      module CompositeLookup
        class Employee
          include Looksist
          attr_accessor :id, :employee_id, :contact_id

          lookup [:name, :location], using=:id
          lookup [:age, :sex], using=:employee_id
          lookup [:pager, :cell], using=:contact_id

          def initialize(id)
            @contact_id = @id = @employee_id = id
          end
        end
      end

      expect(@mock).to receive(:get).once.with('ids/1').and_return({name: 'Employee Name', location: 'Chennai'}.to_json)
      expect(@mock).to receive(:get).once.with('contacts/1').and_return({pager: 'pager', cell: 'cell'}.to_json)
      expect(@mock).to receive(:get).twice.with('employees/1').and_return(nil)
      e = CompositeLookup::Employee.new(1)

      expect(e.name).to eq('Employee Name')
      expect(e.location).to eq('Chennai')

      expect(e.age).to eq(nil)
      expect(e.sex).to eq(nil)

      expect(e.pager).to eq('pager')
      expect(e.cell).to eq('cell')
    end
  end

  context 'share storage between instances' do
    class Employee
      include Looksist
      attr_accessor :id

      lookup [:name, :location], using=:id

      def initialize(id)
        @id = id
      end
    end
    it 'should share storage between instances to improve performance' do
      employee_first_instance = Employee.new(1)
      expect(@mock).to receive(:get).once.with('ids/1')
                       .and_return({name: 'Employee Name', location: 'Chennai'}.to_json)
      employee_first_instance.name

      employee_second_instance = Employee.new(1)
      expect(@mock).not_to receive(:get).with('ids/1')

      employee_second_instance.name
    end
  end
end