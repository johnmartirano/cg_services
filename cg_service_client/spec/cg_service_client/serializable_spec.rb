require 'spec_helper'
require 'cg_service_client/serializable'

module CgServiceClient
  describe Serializable do
    class Klass
      include CgServiceClient::Serializable
      
      serializable_attr_accessor :a1, :a2, :a3
    end

    it 'adds json serialization to a class' do
      obj = Klass.new

      obj.as_json.should == {}

      obj.a1 = 'alpha'
      obj.as_json.should == {'a1' => 'alpha'}

      obj.a2 = 'beta'
      obj.as_json.should == {'a1' => 'alpha',
                             'a2' => 'beta'}

      obj.a3 = 'gamma'
      obj.as_json.should == {'a1' => 'alpha',
                             'a2' => 'beta',
                             'a3' => 'gamma'}
    end

    it 'adds deserialization to a class' do
      source = Klass.new
      source.a1 = 'alpha'
      source.a2 = 'beta'
      source.a3 = 'gamma'

      obj = Klass.new
      obj.a1.should be_nil
      obj.a2.should be_nil
      obj.a3.should be_nil

      obj.from_json(source.to_json)
      obj.a1.should == 'alpha'
      obj.a2.should == 'beta'
      obj.a3.should == 'gamma'
    end
  end
end
