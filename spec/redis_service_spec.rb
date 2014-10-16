require 'spec_helper'

describe Looksist::RedisService do

  class MockRedis
    def pipelined
      yield
    end
  end

  context 'single lookup' do
    before(:each) do
      @lookup = Looksist::RedisService.instance do |lookup|
        lookup.client = {}
        lookup.buffer_size = 1
      end
      @lookup.cache.clear
    end

    it 'should call redis when key not present in cache' do
      expect(@lookup.client).to receive(:get).with('sub_categories/8001').and_return('CEREALI')
      expect(@lookup.sub_category_for(8001)).to eq('CEREALI')
      expect(@lookup.sub_category_for(8001)).to eq('CEREALI')
    end

    it 'should abandon older entries incase of buffer overflow' do
      expect(@lookup.client).to receive(:get).with('sub_families/12').and_return('DON CORLEONE')
      expect(@lookup.client).to receive(:get).with('sub_families/34').and_return('SOPRANOS')

      expect(@lookup.sub_family_for(12)).to eq('DON CORLEONE')
      expect(@lookup.sub_family_for(34)).to eq('SOPRANOS')
      expect(@lookup.cache.keys).to match_array(['sub_families/34'])
    end

  end

  context 'multi lookup' do

    before(:each) do
      @mock = MockRedis.new
      @lookup = Looksist::RedisService.instance do |lookup|
        lookup.client = @mock
        lookup.buffer_size = 5
      end
    end

    it 'should pipeline calls to redis when there are multiple keys' do
      expect(@mock).to receive(:get).with('snacks/1').and_return(OpenStruct.new(value:'BAJJI'))
      expect(@mock).to receive(:get).with('snacks/2').and_return(OpenStruct.new(value:'BONDA'))
      expect(@mock).to receive(:get).with('snacks/3').and_return(OpenStruct.new(value:'VADA'))

      expect(@lookup.snacks_for([1,2,3,1])).to match_array(%w(BAJJI BONDA VADA BAJJI))
    end
  end
end
