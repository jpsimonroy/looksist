require 'spec_helper'


describe Looksist do
  before :each do
    Looksist.lookup_store_client = double('store_lookup_client')
    Looksist.driver = Looksist::Serializers::Her
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
      expect(Looksist.lookup_store_client).to receive(:get).with('employees/1').and_return('Employee Name')
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
      expect(Looksist.lookup_store_client).to receive(:get).with('employees/1').and_return('Employee Name')
      e = ExplicitBucket::Employee.new(1)
      expect(e.name).to eq('Employee Name')
    end
  end

  context 'Lazy Evaluation' do
    module LazyEval
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
      expect(Looksist.lookup_store_client).to_not receive(:get)
      LazyEval::Employee.new(1)
    end
  end

  context 'lookup attributes' do
    it 'should generate declarative attributes on the model with simple lookup value' do
      module SimpleLookup
        class Employee
          include Looksist
          attr_accessor :id
          lookup :name, using= :id

          def initialize(id)
            @id = id
          end
        end
      end

      expect(Looksist.lookup_store_client).to receive(:get).with('ids/1').and_return('Employee Name')
      e = SimpleLookup::Employee.new(1)
      expect(e.name).to eq('Employee Name')
    end

    it 'should generate declarative attributes on the model with object based lookup value' do
      module CompositeLookup
        class Employee
          include Looksist
          attr_accessor :id

          lookup [:name, :location], using=:id

          def initialize(id)
            @id = id
          end
        end
      end

      expect(Looksist.lookup_store_client).to receive(:get).with('ids/1')
                                              .and_return({name: 'Employee Name', location: 'Chennai'}.to_json)
      e = CompositeLookup::Employee.new(1)
      expect(e.name).to eq('Employee Name')
      expect(e.location).to eq('Chennai')
    end
  end
end