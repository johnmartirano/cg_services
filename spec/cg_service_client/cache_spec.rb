require 'spec_helper'
require 'cg_service_client/cache'

module CgServiceClient
  describe Cache do
    before :each do
      @cache = Cache.new(0.1)
    end

    after :each do
      @cache.stop_autoprune
    end

    it 'behaves like a Hash' do
      @cache.set(:key, 'value', 1)
      @cache.get(:key).should == 'value'
    end

    it 'deletes values after timeout' do
      @cache.stop_autoprune

      @cache.set(:key, 'value', 0)
      sleep 1.1

      @cache.entries.size.should == 1
      @cache.get(:key).should be_nil
      @cache.entries.size.should == 0
    end

    it 'auto prunes entries' do
      @cache.set(:key, 'value', 1)
      @cache.entries.size.should == 1
      sleep 2.1
      @cache.entries.size.should == 0
    end
  end
end
