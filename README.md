# Looksist

[![Build Status](https://travis-ci.org/jpsimonroy/looksist.png?branch=master)](https://travis-ci.org/jpsimonroy/looksist)
[![Coverage Status](https://img.shields.io/coveralls/jpsimonroy/looksist.svg)](https://coveralls.io/r/jpsimonroy/looksist?branch=master)
[![Code Climate](https://codeclimate.com/github/jpsimonroy/looksist/badges/gpa.svg)](https://codeclimate.com/github/jpsimonroy/looksist)
[![Gem Version](https://badge.fury.io/rb/looksist.svg)](http://badge.fury.io/rb/looksist)

looksist (adj) - forming positive prejudices based on appearances

Use this gem when you have to lookup attributes from a key-value store based on another attribute as key. This supports redis out-of-the-box and it's blazing fast!

## Installation

Add this line to your application's Gemfile:

    gem 'looksist'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install looksist

## Usage

### With Object Models (Her, Active Resource or any of your choice)

* Add an initializer to configure looksist

``` ruby
Looksist.configure do |looksist|
      looksist.lookup_store = Redis.new(:url => (ENV['REDIS_URL'], :driver => :hiredis)
      looksist.driver =  Looksist::Serializers::Her
end
```
You need to specify the driver to manage the attributes. In this case, we use [HER](https://github.com/remiprev/her). You can add support for ActiveResource or ActiveRecord as needed (also refer to specs for free form usage without a driver).

* Please find the sample rspec to understand the usage and internals

``` ruby
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

      expect(Looksist.lookup_store).to receive(:get).with('ids/1').and_return('Employee Name')
      e = SimpleLookup::Employee.new(1)
      expect(e.name).to eq('Employee Name')
end
```
lookup takes the following form:

``` ruby
# will lookup "employees/#{employee_id}" from the store
lookup :name, using = :employee_id  

# will lookup "stars/#{employee_id}" from the store
lookup :name, using = :employee_id, bucket_name="stars" 

# will lookup "stars/#{employee_id}" from the store 
# for an object with two attributes (name, location)
lookup [:name, :location], using = :employee_id 

```

### With Plain Hashes


#### Columnar Hashes

* First Level look ups

```ruby
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

        inject after: :metrics, at: :table, 
                    using: :employee_id, populate: :employee_name
        inject after: :metrics, at: :table, 
                    using: :employer_id, populate: :employer_name
      end
      # Removed mock expectations, look at the tests for actuals
      expect(HashService.new.metrics).to eq({table: {
          employee_id: [5, 6],
          employer_id: [3, 4],
          employee_name: ['emp 5', 'emp 6'],
          employer_name: ['empr 3', 'empr 4']
      }})
    end
  end

```
* Inner Lookups using [JsonPath](https://github.com/joshbuddy/jsonpath)

```ruby
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

      inject after: :metrics, at: '$.table.database', 
                    using: :employee_id, populate: :employee_name
      inject after: :metrics, at: '$.table.database', 
                    using: :employer_id, populate: :employer_name
    end

    # Mocks removed to keep it simple.
    expect(EmployeeHash.new.metrics).to eq({table: {
        database: {
            employee_id: [15, 16],
            employer_id: [13, 14],
            employee_name: ['emp 15', 'emp 16'],
            employer_name: ['empr 13', 'empr 14']
        }
    }})
  end
```
#### Non Columnar Hashes

```ruby
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

        inject after: :metrics, at: '$.table.menu', 
                        using: :item_id, populate: :item_name
      end

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
```

### Controlling the L2 cache
Looksist has support for an in memory L2 cache which it uses to optimize redis lookups. To disable L2 cache initialize looksists as below. 

* Note that in no L2 cache mode, all lookups would go to redis and the gem would not optimize redundant lookups.
* Hash based lookups would still see optimizations which come from performing unique on keys when injecting values.

```ruby
Looksist.configure do |looksist|
      looksist.lookup_store = Redis.new(:url => (ENV['REDIS_URL'], :driver => :hiredis)
      looksist.driver =  Looksist::Serializers::Her
      looksist.l2_cache = :no_cache
end

```
