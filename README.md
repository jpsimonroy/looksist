# Looksist

[![Build Status](https://travis-ci.org/jpsimonroy/herdis.png?branch=master)](https://travis-ci.org/jpsimonroy/herdis)

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

* Add an initializer to configure looksist

``` ruby
Looksist.lookup_store_client ||= Redis.new(:url => (ENV['REDIS_URL'], :driver => :hiredis)
Looksist.driver = Looksist::Serializers::Her
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

      expect(Looksist.lookup_store_client).to receive(:get).with('ids/1').and_return('Employee Name')
      e = SimpleLookup::Employee.new(1)
      expect(e.name).to eq('Employee Name')
end
```
lookup takes the following form:

``` ruby
lookup :name, using = :employee_id # will lookup "employees/#{employee_id}" from the store

lookup :name, using = :employee_id, bucket_name="stars" # will lookup "stars/#{employee_id}" from the store

lookup [:name, :location], using = :employee_id # will lookup "stars/#{employee_id}" from the store for an object with two attributes (name, location)

```

