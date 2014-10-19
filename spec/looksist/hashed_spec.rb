require 'spec_helper'

describe Looksist::Hashed do
  before(:each) do
    @mock = {}
    Looksist.configure do |looksist|
      looksist.lookup_store = @mock
      looksist.cache_buffer_size = 10
    end
  end

  context 'inject ' do

    it 'should be capable to deep lookup and inject' do
      class Menu
        include Looksist

        def metrics
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

        inject after: :metrics, at: '$.table.menu', using: :item_id, populate: :item_name
      end

      expect(@mock).to receive(:mget).with(['items/1']).and_return(['Idly'])
      expect(@mock).to receive(:mget).with(['items/2']).and_return(['Pongal'])

      expect(Menu.new.metrics).to eq({
                                         table: {
                                             menu: [{
                                                        item_id: 1,
                                                        item_name: 'Idly'
                                                    },
                                                    {
                                                        item_id: 2,
                                                        item_name: 'Pongal'
                                                    }]
                                         }
                                     })
    end

    xit 'should be capable to deep lookup and inject - another example' do
      class NewMenu
        include Looksist

        def metrics
          {
              table: {
                  menu: [
                      {
                          item_id: 4,
                          item_name: 'Idly'
                      },
                      {
                          item_id: 5
                      }
                  ]
              }
          }
        end

        inject after: :metrics, at: '$.table.menu[?(@.item_id=5)]', using: :item_id, populate: :item_name
      end

      expect(@mock).to receive(:get).with('items/5').and_return(OpenStruct.new(value: 'Pongal'))

      expect(NewMenu.new.metrics).to eq(
                                         {
                                             table: {
                                                 menu: [
                                                     {
                                                         item_id: 4,
                                                         item_name: 'Idly'
                                                     },
                                                     {
                                                         item_id: 5,
                                                         item_name: 'Pongal'
                                                     }
                                                 ]
                                             }
                                         }
                                     )
    end

    it 'should be capable to deep lookup and inject on columnar hashes' do
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

      expect(@mock).to receive(:mget).with(['employees/10', 'employees/20']).and_return(['emp 1', 'emp 2'])

      expect(DeepHash.new.metrics).to eq({table: {
          inner_table: {
              employee_id: [10, 20],
              employee_name: ['emp 1', 'emp 2']
          }
      }})
    end

    it 'should inject single attribute to an existing hash' do
      class HashService1
        include Looksist

        def metrics
          {
              table: {
                  employee_id: [1, 2]
              }
          }
        end

        inject after: :metrics, at: :table, using: :employee_id, populate: :employee_name
      end

      expect(@mock).to receive(:mget).with(['employees/1', 'employees/2']).and_return(['emp 1', 'emp 2'])

      expect(HashService1.new.metrics).to eq({table: {
          employee_id: [1, 2],
          employee_name: ['emp 1', 'emp 2']
      }})
    end

    it 'should inject multiple attribute to an existing hash' do
      class HashService
        include Looksist

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

      expect(@mock).to receive(:mget).with(['employees/5', 'employees/6']).and_return(['emp 5', 'emp 6'])

      expect(@mock).to receive(:mget).with(['employers/3', 'employers/4']).and_return(['empr 3', 'empr 4'])

      expect(HashService.new.metrics).to eq({table: {
          employee_id: [5, 6],
          employer_id: [3, 4],
          employee_name: ['emp 5', 'emp 6'],
          employer_name: ['empr 3', 'empr 4']
      }})
    end
  end

  it 'should inject multiple attribute to an existing deep hash' do
    class EmployeeHash
      include Looksist

      def metrics
        {
            table: {
                database: {
                    employee_id: [15, 16],
                    employer_id: [13, 14]
                }
            }
        }
      end

      inject after: :metrics, at: '$.table.database', using: :employee_id, populate: :employee_name
      inject after: :metrics, at: '$.table.database', using: :employer_id, populate: :employer_name
    end

    expect(@mock).to receive(:mget).with(['employees/15', 'employees/16']).and_return(['emp 15', 'emp 16'])

    expect(@mock).to receive(:mget).with(['employers/13', 'employers/14']).and_return(['empr 13', 'empr 14'])

    expect(EmployeeHash.new.metrics).to eq({table: {
        database: {
            employee_id: [15, 16],
            employer_id: [13, 14],
            employee_name: ['emp 15', 'emp 16'],
            employer_name: ['empr 13', 'empr 14']
        }
    }})
  end


  context 'multiple methods and injections' do
    it 'should inject multiple attribute to an existing hash' do
      class HashServiceSuper
        include Looksist

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

      expect(@mock).to receive(:mget).with(['shrinks/1', 'shrinks/2']).and_return(['shrink 1', 'shrink 2'])

      expect(@mock).to receive(:mget).with(['dcs/7', 'dcs/8']).and_return(['dc 7', 'dc 8'])

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