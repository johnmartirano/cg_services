require 'spec_helper'

class CgLookupClient::CachingEndpointSet
  describe Key do
    it 'is frozen on initialization' do
      key = Key.new('mod', 'type', 'version')
      key.frozen?.should be_true
    end

    it 'implements to_s' do
      key = Key.new('mod', 'type', '1')
      "#{key}".should == 'type-v1(mod)'
    end

    it 'behaves as a hash key' do
      key1 = Key.new(Key, 'type', '1')
      key2 = Key.new(Key, 'type', '1')

      key1.equal?(key2).should be_false
      key1.should == key2
      key1.hash.should == key2.hash
    end
  end
end
