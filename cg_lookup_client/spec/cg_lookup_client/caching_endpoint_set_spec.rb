require 'spec_helper'

require 'logger'
require 'set'

module CgLookupClient
  # Just a mock service to use during testing.
  class TestService
    include UriWithVersion

    attr_accessor :name, :alive

    def initialize(name, uri, version)
      @name = name
      set_uri_and_version(uri, version)
      @alive = true
    end
    
    def ping
      @alive
    end
  end

  class NotAliveService < TestService
    def ping
      false
    end
  end

  # Just a mock service to use during testing.
  class AliveService < TestService
    def ping
      true
    end
  end

  describe CachingEndpointSet do
    # Create a new RestEndpoint with some methods stubbed for testing.
    # It will return lookups for a service with the same uri and
    # version as the RestEndpoint itself.
    def new_endpoint(opts = {})
      opts = {
        :uri       => 'http://example.com',
        :version   => '1',
        :type_name => 'TestService',
        :desc      => 'description of TestService'
      }.merge(opts)

      endpoint = RestEndpoint.new(opts[:uri], opts[:version])
      endpoint.stub(:lookup) do |type|
        if type == opts[:type_name]
          [{:entry => Entry.new(:type_name => opts[:type_name],
                                :version => opts[:version],
                                :uri => opts[:uri]),
             :message => 'ok'}]
        else
          [{:entry => nil, :message => 'not found'}]
        end
      end

      endpoint
    end

    before(:each) do
      @set = CachingEndpointSet.new(:auto_refresh => false)
      @set.logger.level = Logger::FATAL
    end

    describe '#add' do
      it 'adds multiple endpoints' do
        @set.size.should == 0
        @set.add new_endpoint(:uri => 'one')
        @set.size.should == 1
        @set.add new_endpoint(:uri => 'two')
        @set.size.should == 2
        @set.add new_endpoint(:uri => 'three')
        @set.size.should == 3
      end

      it 'does not add duplicate endpoints' do
        @set.size.should == 0
        2.times do
          @set.add new_endpoint
        end
        @set.size.should == 1
      end

      it 'rejects unsupported endpoints' do
        expect {
          @set.add new_endpoint(:version => 999999)
        }.to raise_error(UnsupportedEndpointVersionError)
      end
    end

    describe '#get' do
      it 'gets a registered service' do
        @set.add new_endpoint(:type_name => 'TestService', :version => '1')
        @set.get(AliveService, 'TestService', '1').uri.should == 'http://example.com'
      end

      it 'gets a registered service from multiple endpoints' do
        names = ['a', 'b', 'c', 'd']

        names.each do |name|
          @set.add new_endpoint(:uri => name, :type_name => name)
        end

        @set.size.should == names.size

        names.each do |name|
          @set.get(AliveService, name, '1').uri.should == name
        end
      end

      it 'gets from cache' do
        @set.add new_endpoint(:type_name => 'TestService', :version => '1')
        endpoint = @set.get(AliveService, 'TestService', '1')
        endpoint.uri.should == 'http://example.com'
        10.times do
          endpoint.equal?(@set.get(AliveService, 'TestService', '1')).should be_true
        end
      end

      it 'distributes somewhat randomly' do
        @set.add new_endpoint(:uri => 'a')
        @set.add new_endpoint(:uri => 'b')
        @set.add new_endpoint(:uri => 'c')

        counts = Hash.new {|hash, key| hash[key] = 0}

        100.times do
          endpoint = @set.get(AliveService, 'TestService', '1')
          counts[endpoint.uri] += 1
        end

        counts.size.should == 3
        # 100 calls to #get across three endpoints means expected
        # value is 33 each.  We should get at least 10 of each, or
        # we're really unlucky.
        counts.each do |uri, count|
          count.should > 10
        end
      end

      it 'does not return evicted endpoint' do
        @set.add new_endpoint(:uri => 'to_evict')
        @set.add new_endpoint(:uri => 'b')
        @set.add new_endpoint(:uri => 'c')

        counts = Hash.new {|hash, key| hash[key] = 0}

        20.times do
          endpoint = @set.get(AliveService, 'TestService', '1')
          counts[endpoint.uri] += 1

          if endpoint.uri == 'to_evict'
            @set.evict! endpoint
          end
        end

        counts.size.should == 3
        counts['to_evict'].should == 1
      end

      it 'raises error when no endpoint responds to ping' do
        @set.add new_endpoint
        expect {
          @set.get(NotAliveService, 'TestService', '1')
        }.to raise_error(NotFoundError)
      end

      it 'raises error when no endpoint exists' do
        @set.add new_endpoint
        expect {
          @set.get(AliveService, 'NoSuchService', '1')
        }.to raise_error(NotFoundError)
      end
    end

    describe '.lookup_in_background' do
      # Make sure our CachingEndpointSet is doing background
      # refreshes and doing them often so our tests needn't take
      # forever.
      before(:each) do
        @set = CachingEndpointSet.new(:refresh_period => 0.1)
        @set.logger.level = Logger::FATAL
      end

      it 'refreshes endpoints in the background' do
        @set.add new_endpoint

        endpoint = @set.get(TestService, 'TestService', '1')

        sleep 0.2
        # refresh should be triggered, but cached endpoint is returned immediately
        endpoint.equal?(@set.get(TestService, 'TestService', '1')).should be_true

        sleep 0.1
        # now refresh should be done
        endpoint.equal?(@set.get(TestService, 'TestService', '1')).should be_false
      end

      # This test doesn't make much sense on MRI, but does test
      # threadsafety somewhat in JRuby.
      it 'serves many threads with #get while refreshing in the background' do
        @set.add new_endpoint

        threads = (1..10).map do
          Thread.new do
            100.times do
              endpoint = @set.get(TestService, 'TestService', '1')
              endpoint.name.should == 'TestService'
              @set.evict!(endpoint) if rand(10) == 0
              sleep 0.01
            end
          end
        end

        threads.each(&:join)
      end

      # This test doesn't make much sense on MRI, but does test
      # threadsafety somewhat in JRuby.
      it 'serves many threads with #with_endpoint while refreshing in the background' do
        @set.add new_endpoint

        threads = (1..10).map do
          Thread.new do
            100.times do
              begin
                @set.with_endpoint(TestService, 'TestService', '1') do |endpoint|
                  endpoint.name.should == 'TestService'
                  raise(Errno::ECONNREFUSED, 'deliberate test error') if (rand(10) == 0)
                end
              rescue => e
                raise unless e.message =~ /deliberate/
              end
              sleep 0.01
            end
          end
        end

        threads.each(&:join)
      end
    end

    describe '#refresh' do
      it 'forces a lookup' do
        @set.add new_endpoint
        e1 = @set.get(TestService, 'TestService', '1')
        @set.refresh(TestService, 'TestService', '1')
        e2 = @set.get(TestService, 'TestService', '1')
        e1.equal?(e2).should be_false
      end
    end

    describe '#with_endpoint' do
      it 'yields an endpoint' do
        @set.add new_endpoint

        @set.with_endpoint(TestService, 'TestService', '1') do |endpoint|
          endpoint.name.should == 'TestService'
          endpoint.version.should == '1'
        end
      end

      it 'gives up after n tries' do
        @set.add new_endpoint

        tries = 0
        expect {
          @set.with_endpoint(TestService, 'TestService', '1') do |endpoint|
            tries += 1
            raise Errno::ECONNREFUSED, 'deliberate test exception'
          end
        }.to raise_error(Errno::ECONNREFUSED)
        tries.should == 2

        tries = 0
        expect {
          @set.with_endpoint(TestService, 'TestService', '1', :tries => 6) do |endpoint|
            tries += 1
            raise Errno::ECONNREFUSED, 'deliberate test exception'
          end
        }.to raise_error(Errno::ECONNREFUSED)
        tries.should == 6
      end

      it 'evicts an endpoint when exception is raised' do
        lookup_endpoint = new_endpoint
        @set.add lookup_endpoint

        tries = 0

        expect {
          @set.with_endpoint(TestService, 'TestService', '1') do |endpoint|
            tries += 1

            if tries == 1
              # simulate a dead service, so next try should be NotFoundError
              lookup_endpoint.stub(:lookup) do
                [{:entry => nil, :message => 'not found'}]
              end

              # triggers eviction
              raise Errno::ECONNREFUSED, 'deliberate test exception'
            end
          end
        }.to raise_error(NotFoundError)

        tries.should == 1
      end
    end
  end
end
