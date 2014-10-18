require 'spec_helper'

describe Looksist::SafeLruCache do

  before :each do
    @cache = Looksist::SafeLruCache.new(3)
  end

  context 'one entry' do

    it 'should hold only entries limited by max size' do
      @cache[:a] = 1
      @cache[:b] = 2
      @cache[:c] = 3
      @cache[:d] = 4
      expect(@cache.size).to eq(3)
      expect(@cache.keys).to match_array([:b, :c, :d])
    end

  end

  context 'multiple entries' do

    it 'should flush other entries when new entries are added' do
      @cache = Looksist::SafeLruCache.new(3)
      @cache[:a] = 1
      @cache[:b] = 2
      @cache.merge!(c: 3, d: 4, e: 5)
      expect(@cache.size).to eq(3)
      expect(@cache.keys).to match_array([:c, :d, :e])
    end

    it 'race conditions when actual size equals max size' do
      @cache[:a] = 1
      @cache[:b] = 2
      @cache.merge!(c: 3)
      expect(@cache.size).to eq(3)
      expect(@cache.keys).to match_array([:a, :b, :c])
    end

  end

  context '#mslice' do
    it 'should slice hash for repeating keys' do
      @cache.merge!(a: 1, b: 2, c: 3)
      expect(@cache.mslice([:a, :b, :c, :a, :b])).to match_array([1, 2, 3, 1, 2])
    end
  end

end
