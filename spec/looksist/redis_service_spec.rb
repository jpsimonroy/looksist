require 'spec_helper'

describe Looksist::RedisService do

  context 'single lookup' do
    before(:each) do
      @lookup = Looksist::RedisService.instance do |lookup|
        lookup.client = {}
        lookup.buffer_size = 1
      end
      @lookup.cache.clear
    end

    it 'should call redis when key not present in cache' do
      expect(@lookup.client).to receive(:get).once.with('sub_categories/8001').and_return('CEREALI')
      expect(@lookup.sub_category_for(8001)).to eq('CEREALI')
      expect(@lookup.sub_category_for(8001)).to eq('CEREALI')
    end

    it 'should abandon older entries incase of buffer overflow' do
      expect(@lookup.client).to receive(:get).once.with('sub_families/12').and_return('DON CORLEONE')
      expect(@lookup.client).to receive(:get).once.with('sub_families/34').and_return('SOPRANOS')

      expect(@lookup.sub_family_for(12)).to eq('DON CORLEONE')
      expect(@lookup.sub_family_for(34)).to eq('SOPRANOS')
      expect(@lookup.cache.keys).to match_array(['sub_families/34'])
    end

  end

  context 'multi lookup' do

    before(:each) do
      @mock = {}
      @lookup = Looksist::RedisService.instance do |lookup|
        lookup.client = @mock
        lookup.buffer_size = 5
      end
    end

    it 'should mget redis when there are multiple keys' do
      expect(@mock).to receive(:mget).with('snacks/1', 'snacks/2', 'snacks/3').once.and_return(%w(BAJJI BONDA VADA))
      expect(@lookup.snacks_for([1, 2, 3])).to match_array(%w(BAJJI BONDA VADA))
    end

    it 'should mget redis only for unique keys' do
      expect(@mock).to receive(:mget).with('snacks/1', 'snacks/2', 'snacks/3').once.and_return(%w(BAJJI BONDA VADA))
      expect(@lookup.snacks_for([1, 2, 3, 1, 2])).to match_array(%w(BAJJI BONDA VADA BAJJI BONDA))
    end

    it 'should get from cache' do
      expect(@mock).to receive(:mget).with('snacks/1', 'snacks/2', 'snacks/3', 'snacks/4', 'snacks/5').once.and_return(%w(BAJJI BONDA VADA MEDU_VADA MASALA_VADA))
      expect(@lookup.snacks_for([1, 2, 3, 4, 5])).to match_array(%w(BAJJI BONDA VADA MEDU_VADA MASALA_VADA))
      expect(@lookup.snacks_for([1, 2, 3, 4, 5])).to match_array(%w(BAJJI BONDA VADA MEDU_VADA MASALA_VADA))
    end
  end

  context 'value not present' do
    before(:each) do
      @mock = {}
      @lookup = Looksist::RedisService.instance do |lookup|
        lookup.client = @mock
        lookup.buffer_size = 5
      end
    end

    it 'should not bomb when there are no values present' do
      expect(@mock).to receive(:mget).with('snacks/1', 'snacks/2', 'snacks/3').once.and_return(['BAJJI', nil, 'VADA'])
      expect(@lookup.snacks_for([1, 2, 3])).to match_array(['BAJJI', nil, 'VADA'])
    end
  end

  context 'flush local cache' do
    before(:each) do
      @mock = {}
      @lookup = Looksist::RedisService.instance do |lookup|
        lookup.client = @mock
        lookup.buffer_size = 5
      end
    end

    it 'should clear the local cache' do
      expect(@mock).to receive(:mget).with('snacks/1', 'snacks/2', 'snacks/3').once.and_return(['BAJJI', nil, 'VADA'])
      @lookup.snacks_for([1, 2, 3])
      expect(@lookup.cache.size).to eq(3)
      @lookup.flush_cache!
      expect(@lookup.cache).to be_empty
    end
  end
end
