require 'spec_helper'

describe Looksist::Hashed do
  before(:each) do
    class MockRedis
      def pipelined
        yield
      end
    end

    @mock = MockRedis.new

    Looksist::Hashed.redis_service = Looksist::RedisService.instance do |lookup|
      lookup.client = @mock
    end
  end


  context 'inject ' do

    it 'should be capable to deep lookup and inject' do
      class DeepHash
        include Looksist::Hashed

        def metrics
          {
              table: {
                  inner_table: {
                      employee_id: [10, 20]
                  }
              }
          }
        end

        inject after: :metrics, at: 'table.inner_table', using: :employee_id, populate: :employee_name
      end

      expect(@mock).to receive(:get).with('employees/10').and_return(OpenStruct.new(value: 'emp 1'))
      expect(@mock).to receive(:get).with('employees/20').and_return(OpenStruct.new(value: 'emp 2'))

      expect(DeepHash.new.metrics).to eq({table: {
          inner_table: {
              employee_id: [10, 20],
              employee_name: ['emp 1', 'emp 2']
          }
      }})
    end
    it 'should inject single attribute to an existing hash' do
      class HashService1
        include Looksist::Hashed

        def metrics
          {
              table: {
                  employee_id: [1, 2]
              }
          }
        end

        inject after: :metrics, at: :table, using: :employee_id, populate: :employee_name
      end

      expect(@mock).to receive(:get).with('employees/1').and_return(OpenStruct.new(value: 'emp 1'))
      expect(@mock).to receive(:get).with('employees/2').and_return(OpenStruct.new(value: 'emp 2'))

      expect(HashService1.new.metrics).to eq({table: {
          employee_id: [1, 2],
          employee_name: ['emp 1', 'emp 2']
      }})
    end

    it 'should inject multiple attribute to an existing hash' do
      class HashService
        include Looksist::Hashed

        def metrics
          {
              table: {
                  employee_id: [5, 6],
                  employer_id: [3, 4]
              }
          }
        end

        inject after: :metrics, at: :table, using: :employee_id, populate: :employee_name
        inject after: :metrics, at: :table, using: :employer_id, populate: :employer_name
      end

      expect(@mock).to receive(:get).with('employees/5').and_return(OpenStruct.new(value: 'emp 5'))
      expect(@mock).to receive(:get).with('employees/6').and_return(OpenStruct.new(value: 'emp 6'))

      expect(@mock).to receive(:get).with('employers/3').and_return(OpenStruct.new(value: 'empr 3'))
      expect(@mock).to receive(:get).with('employers/4').and_return(OpenStruct.new(value: 'empr 4'))

      expect(HashService.new.metrics).to eq({table: {
          employee_id: [5, 6],
          employer_id: [3, 4],
          employee_name: ['emp 5', 'emp 6'],
          employer_name: ['empr 3', 'empr 4']
      }})
    end
  end


  context 'multiple methods and injections' do
    it 'should inject multiple attribute to an existing hash' do
      class HashServiceSuper
        include Looksist::Hashed

        def shrinkage
          {
              table: {
                  shrink_id: [1, 2]
              }
          }
        end

        def stock
          {
              table: {
                  dc_id: [7, 8]
              }
          }
        end

        inject after: :shrinkage, at: :table, using: :shrink_id, populate: :shrink_name
        inject after: :stock, at: :table, using: :dc_id, populate: :dc_name
      end

      expect(@mock).to receive(:get).with('shrinks/1').and_return(OpenStruct.new(value: 'shrink 1'))
      expect(@mock).to receive(:get).with('shrinks/2').and_return(OpenStruct.new(value: 'shrink 2'))

      expect(@mock).to receive(:get).with('dcs/7').and_return(OpenStruct.new(value: 'dc 7'))
      expect(@mock).to receive(:get).with('dcs/8').and_return(OpenStruct.new(value: 'dc 8'))

      hash_service_super = HashServiceSuper.new
      expect(hash_service_super.shrinkage).to eq({table: {
          shrink_id: [1, 2],
          shrink_name: ['shrink 1', 'shrink 2']
      }})

      expect(hash_service_super.stock).to eq({table: {
          dc_id: [7, 8],
          dc_name: ['dc 7', 'dc 8']
      }})
    end

  end
end