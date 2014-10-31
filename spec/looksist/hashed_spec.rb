require 'spec_helper'

describe Looksist::Hashed do
  context('with_l2_cache') do
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

        expect(@mock).to receive(:mget).once.with(*%w(items/1 items/2)).and_return(%w(Idly Pongal))

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


      it 'should be capable to deep lookup and inject from custom bucket' do
        class CustomizedMenu
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

          inject after: :metrics, at: '$.table.menu', using: :item_id, populate: :item_name, bucket_name: 'menu_items'
        end

        expect(@mock).to receive(:mget).once.with(*%w(menu_items/1 menu_items/2)).and_return(%w(Idly Pongal))

        expect(CustomizedMenu.new.metrics).to eq({
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

        expect(@mock).to receive(:mget).with(*%w(employees/10 employees/20)).and_return(['emp 1', 'emp 2'])

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

        expect(@mock).to receive(:mget).with(*%w(employees/1 employees/2)).and_return(['emp 1', 'emp 2'])

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

        expect(@mock).to receive(:mget).with(*%w(employees/5 employees/6)).and_return(['emp 5', 'emp 6'])

        expect(@mock).to receive(:mget).with(*%w(employers/3 employers/4)).and_return(['empr 3', 'empr 4'])

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

      expect(@mock).to receive(:mget).with(*%w(employees/15 employees/16)).and_return(['emp 15', 'emp 16'])

      expect(@mock).to receive(:mget).with(*%w(employers/13 employers/14)).and_return(['empr 13', 'empr 14'])

      expect(EmployeeHash.new.metrics).to eq({table: {
          database: {
              employee_id: [15, 16],
              employer_id: [13, 14],
              employee_name: ['emp 15', 'emp 16'],
              employer_name: ['empr 13', 'empr 14']
          }
      }})
    end

    context 'handle no data' do
      it 'should not inject when data is not available' do
        class EmptyResponse
          include Looksist

          def empty
            {:high_stock => {}, :low_shelf_life => {}, :in_elimination => {}, :inactive_with_stock => {}}
          end

          inject after: :empty, at: :high_stock,
                 using: :sub_category_id, populate: :sub_category

          inject after: :empty, at: '$.low_shelf_life',
                 using: :sub_category_id, populate: :sub_category

          inject after: :empty, at: '$.in_elimination',
                 using: :sub_category_id, populate: :sub_category

          inject after: :empty, at: '$.inactive_with_stock',
                 using: :sub_category_id, populate: :sub_category
        end
        expected_response = {:high_stock => {}, :low_shelf_life => {}, :in_elimination => {}, :inactive_with_stock => {}}
        expect(EmptyResponse.new.empty).to eq(expected_response)
      end

      it 'should be capable to deep lookup and inject' do
        class EmptyMenu
          include Looksist

          def metrics
            {
                table: {
                    menu: []
                }
            }
          end

          inject after: :metrics, at: '$.table.menu', using: :item_id, populate: :item_name
        end

        expect(EmptyMenu.new.metrics).to eq({
                                                table: {
                                                    menu: []
                                                }
                                            })
      end
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

        expect(@mock).to receive(:mget).with(*%w(shrinks/1 shrinks/2)).and_return(['shrink 1', 'shrink 2'])

        expect(@mock).to receive(:mget).with(*%w(dcs/7 dcs/8)).and_return(['dc 7', 'dc 8'])

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

  context('no l2 cache') do
    before(:each) do
      @mock = {}
      Looksist.configure do |looksist|
        looksist.lookup_store = @mock
        looksist.l2_cache = :no_cache
      end
    end

    it 'should be capable to deep lookup and inject on columnar hashes' do
      class NoL2DeepHash
        include Looksist

        def metrics
          {
              table: {
                  inner_table: {
                      employee_id: [10, 10]
                  }
              }
          }
        end

        inject after: :metrics, at: '$.table.inner_table', using: :employee_id, populate: :employee_name
      end

      expect(@mock).to receive(:mget).with(*%w(employees/10)).and_return(['emp 1'])

      expect(NoL2DeepHash.new.metrics).to eq({table: {
          inner_table: {
              employee_id: [10, 10],
              employee_name: ['emp 1', 'emp 1']
          }
      }})
    end

    it 'should work for first level of substitution' do
      class FirstLevelHash
        include Looksist

        def metrics
          {employee_id: 10}
        end

        inject after: :metrics, using: :employee_id, populate: :employee_name
      end

      expect(@mock).to receive(:get).with('employees/10').and_return('emp 1')

      expect(FirstLevelHash.new.metrics).to eq({
                                                   employee_id: 10,
                                                   employee_name: 'emp 1'
                                               })
    end

    it 'should work for array of hashes' do
      class ArrayOfHashes
        include Looksist

        def metrics
          [
              {
                  item_id: 1
              },
              {
                  item_id: 2
              }
          ]
        end

        inject after: :metrics, at: '$', using: :item_id, populate: :item_name, as: {item_name: 'dish_name'}
      end

      expect(@mock).to receive(:mget).once.with(*%w(items/1 items/2)).and_return(%w(Idly Pongal))

      expect(ArrayOfHashes.new.metrics).to eq(
                                               [{
                                                    item_id: 1,
                                                    dish_name: 'Idly'
                                                },
                                                {
                                                    item_id: 2,
                                                    dish_name: 'Pongal'
                                                }]
                                           )

    end

    it 'should work for multiple attributes' do
      class HashWithMultipleAttributes
        include Looksist

        def metrics
          [
              {
                  hero_id: 1
              },
              {
                  hero_id: 2
              }
          ]
        end

        inject after: :metrics, at: '$', using: :hero_id, populate: [:name, :mnemonic], as: {name: 'hero_name', mnemonic: 'hero_mnemonic'}
      end
      js1 = {name: 'Rajini', mnemonic: 'SuperStart'}.to_json
      js2 = {name: 'Kamal', mnemonic: 'Ulaganayagan'}.to_json
      jsons = [js1, js2]
      expect(@mock).to receive(:mget).once.with(*%w(heros/1 heros/2)).and_return(jsons)

      expect(HashWithMultipleAttributes.new.metrics).to eq(
                                                            [{:hero_id => 1, :hero_name => 'Rajini', :hero_mnemonic => 'SuperStart'},
                                                             {:hero_id => 2, :hero_name => 'Kamal', :hero_mnemonic => 'Ulaganayagan'}]
                                                        )
    end

    it 'should work for class methods' do
      class SelfHelp
        include Looksist

        def self.help_me
          [
              {
                  a: 1
              }
          ]
        end

        inject after: :help_me, at: '$', using: :a, bucket_name: 'ids', populate: :name
      end

      expect(@mock).to receive(:mget).once.with('ids/1').and_return(['RajiniKanth'])
      expect(SelfHelp.help_me).to eq([{:a => 1, :name => 'RajiniKanth'}])
    end

    it 'should work for first level hashes in class methods' do
      class FirstLevelClass
        include Looksist

        class << self
          def my_method
            {
                a: 1
            }
          end
        end

        inject after: :my_method, using: :a, bucket_name: 'ids', populate: :name
      end

      expect(@mock).to receive(:get).once.with('ids/1').and_return('RajiniKanth')
      expect(FirstLevelClass.my_method).to eq({:a => 1, :name => 'RajiniKanth'})
    end

    it 'should be capable to deep lookup and inject multiple attributes' do
      class DeepLookUpMultiple
        include Looksist

        def self.metrics
          {
              table: {
                  menu: {
                      item_id: [1, 2]
                  }
              }
          }
        end

        inject after: :metrics, at: '$.table.menu', using: :item_id, populate: [:name, :mnemonic], as: {name: 'item_name', mnemonic: 'item_mnemonic'}
      end

      js1 = {name: 'Rice Cake', mnemonic: 'Idly'}.to_json
      js2 = {name: 'Rice pudding', mnemonic: 'Pongal'}.to_json
      jsons = [js1, js2]

      expect(@mock).to receive(:mget).once.with(*%w(items/1 items/2)).and_return(jsons)

      expect(DeepLookUpMultiple.metrics).to eq({:table => {:menu => {:item_id => [1, 2], :item_name => ['Rice Cake', 'Rice pudding'], :item_mnemonic => ['Idly', 'Pongal']}}})
    end

    it 'should be capable to deep lookup and inject multiple attributes ignoring nil values' do
      class DeepLookUpMultipleIngnorNil
        include Looksist

        def self.metrics
          {
              table: {
                  menu: {
                      item_id: [1, 2]
                  }
              }
          }
        end

        inject after: :metrics, at: '$.table.menu', using: :item_id, populate: [:name, :mnemonic], as: {name: 'item_name', mnemonic: 'item_mnemonic'}
      end

      js1 = {name: 'Rice Cake', mnemonic: 'Idly'}.to_json
      jsons = [js1, nil]

      expect(@mock).to receive(:mget).once.with(*%w(items/1 items/2)).and_return(jsons)

      expect(DeepLookUpMultipleIngnorNil.metrics).to eq({:table => {:menu => {:item_id => [1, 2], :item_name => ['Rice Cake', nil], :item_mnemonic => ['Idly', nil]}}})
    end

    it 'should be capable to deep lookup and inject multiple attributes in same order' do
      class ColumnarWithNil
        include Looksist

        def self.metrics
          {
              table: {
                  menu: {
                      item_id: [1, 2, 2, 1, 1, 2, 3, 3, 2, 1]
                  }
              }
          }
        end

        inject after: :metrics, at: '$.table.menu', using: :item_id, populate: [:name, :mnemonic], as: {name: 'item_name', mnemonic: 'item_mnemonic'}
      end

      class ColumnarWithEmpty
        include Looksist

        def self.metrics
          {
              table: {
                  menu: {
                      item_id: []
                  }
              }
          }
        end

        inject after: :metrics, at: '$.table.menu', using: :item_id, populate: [:name, :mnemonic], as: {name: 'item_name', mnemonic: 'item_mnemonic'}
      end

      js1 = {name: 'Rice Cake', mnemonic: 'Idly'}.to_json
      js2 = {name: 'Pan Cake', mnemonic: 'Dosa'}.to_json
      jsons = [js1, js2, nil]

      expect(@mock).to receive(:mget).once.with(*%w(items/1 items/2 items/3)).and_return(jsons)

      expect(ColumnarWithNil.metrics).to eq({:table => {:menu => {
          :item_id => [1, 2, 2, 1, 1, 2, 3, 3, 2, 1],
          :item_name => ['Rice Cake', 'Pan Cake', 'Pan Cake', 'Rice Cake', 'Rice Cake', 'Pan Cake', nil, nil, 'Pan Cake', 'Rice Cake'],
          :item_mnemonic => ['Idly', 'Dosa', 'Dosa', 'Idly', 'Idly', 'Dosa', nil, nil, 'Dosa', 'Idly']}}})

      expect(ColumnarWithEmpty.metrics).to eq({
                                                  table: {
                                                      menu: {
                                                          item_id: [],
                                                          item_name: [],
                                                          item_mnemonic: []
                                                      }
                                                  }
                                              })
    end
  end
end
