require 'spec_helper'

require 'set'

module CgLookupClient
  class TestClass
    include UriWithVersion

    def initialize(uri, version)
      set_uri_and_version(uri, version)
    end
  end
  
  describe UriWithVersion do
    it 'provides uri, version, uri_with_version methods' do
      o = TestClass.new('http://example.com/', '12')

      o.should respond_to(:uri)
      o.should respond_to(:version)
      o.should respond_to(:uri_with_version)

      o.uri.should == 'http://example.com/'
      o.version.should == '12'
      o.uri_with_version.should == 'http://example.com/v12/'
    end

    it 'adds trailing slash' do
      o = TestClass.new('http://example.com', '12')
      o.uri_with_version.should == 'http://example.com/v12/'
    end

    it 'does not modify uri' do
      o = TestClass.new('http://example.com', '12')
      o.uri.should == 'http://example.com'
      o = TestClass.new('a', '12')
      o.uri.should == 'a'
    end

    it 'accepts numeric version' do
      o = TestClass.new('http://example.com/', 15)
      o.uri_with_version.should == 'http://example.com/v15/'
    end

    describe '#eql?' do
      it 'compares by uri with version' do
        a = TestClass.new('http://example.com/', 15)
        b = TestClass.new('http://example.com', 15)
        a.should == b
        (a.eql?(b)).should be_true
      end

      it 'returns falsy with different uri' do
        a = TestClass.new('http://a.example.com/', 15)
        b = TestClass.new('http://b.example.com/', 15)
        a.should_not == b
        (a.eql?(b)).should be_false
      end

      it 'returns falsy with different version' do
        a = TestClass.new('http://example.com/', 1)
        b = TestClass.new('http://example.com/', 2)
        a.should_not == b
        (a.eql?(b)).should be_false
      end
    end

    it 'behaves as a hash value' do
      hash = Hash.new
      hash[:key] = TestClass.new('http://example.com/', 1)
      hash.has_value?(TestClass.new('http://example.com', 1)).should be_true
    end

    it 'behaves as a hash key' do
      hash = Hash.new

      hash[TestClass.new('http://example.com/', 1)] = :ok
      hash[TestClass.new('http://example.com', 1)] = :ok
      hash.size.should == 1

      hash[TestClass.new('http://example.com/', 2)] = :ok
      hash[TestClass.new('http://example.com', 3)] = :ok
      hash.size.should == 3
    end

    it 'behaves in a set' do
      set = Set.new
      set.add TestClass.new('http://example.com/', 1)
      set.add TestClass.new('http://example.com/', 1)
      set.size.should == 1
    end
  end
end
