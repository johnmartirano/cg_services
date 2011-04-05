require File.dirname(__FILE__) + '/../lookup_service'
require 'rspec'
require 'rack/test'

include CgLookupService

CgLookupService::App.set :environment, :development

def app
  CgLookupService::App
end

describe "lookup service" do
  include Rack::Test::Methods

  before(:each) do
    header 'Accept', 'application/json'
    Entry.delete_all
    @attributes = {
        :type_name => "lookup",
        :description => "CG Lookup Service",
        :version => "1",
        :uri => "http://localhost:3000"}
  end

  describe "GET /v1/entries" do
    it "should return 2 entries" do
      Entry.create(@attributes)
      Entry.create({
        :type_name => "lookup",
        :description => "CG Lookup Service",
        :version => "1",
        :uri => "http://localhost:3001"})

      get '/v1/entries'
      last_response.should be_ok
      JSON.parse(last_response.body).should have(2).items
    end

  end

  describe "POST on /v1/entries" do
    it "should register an entry" do
      post '/v1/entries', @attributes.to_json
      last_response.should be_ok

      get '/v1/entries'
      attributes = JSON.parse(last_response.body)[0]
      attributes["type_name"].should  == "lookup"
      attributes["description"].should == "CG Lookup Service"
      attributes["version"].should   == "1"
      attributes["uri"].should == "http://localhost:3000"
    end

    it "should not register duplicate entries" do
      post '/v1/entries', @attributes.to_json
      post '/v1/entries', @attributes.to_json

      get '/v1/entries'
      last_response.should be_ok
      JSON.parse(last_response.body).should have(1).item
    end

    it "should error when incomplete attributes are provided" do
      attributes = {
        :type_name => "lookup",
        :version => "1"}

      post '/v1/entries', attributes.to_json
      last_response.status.should == 500

      attributes = {
        :type_name => "lookup",
        :uri => "http://localhost:3000"}

      post '/v1/entries', attributes.to_json
      last_response.status.should == 500

      attributes = {
        :version => "1",
        :uri => "http://localhost:3000"}

      post '/v1/entries', attributes.to_json
      last_response.status.should == 500
    end

    it "should renew an already registered entry" do
      post '/v1/entries', @attributes.to_json
      get '/v1/entries'
      attributes = JSON.parse(last_response.body)[0]
      updated_at_1 = attributes["updated_at"]

      sleep(2)
      
      post '/v1/entries', @attributes.to_json
      get '/v1/entries'
      attributes = JSON.parse(last_response.body)[0]
      updated_at_2 = attributes["updated_at"]

      updated_at_1.should_not == updated_at_2
    end

    it "should remove an expired entry" do
      CgLookupService::App.lease_time=2
      CgLookupService::App.lease_expiry_interval=1
      post '/v1/entries', @attributes.to_json
      sleep(10)

      get '/v1/entries'
      last_response.status.should == 404
    end

  end

  describe "DELETE on /v1/entries" do
    it "should remove an entry by id" do
      post '/v1/entries', @attributes.to_json
      attributes = JSON.parse(last_response.body)
      delete "/v1/entries/#{attributes['id']}"
      last_response.should be_ok
    end
  end
end
