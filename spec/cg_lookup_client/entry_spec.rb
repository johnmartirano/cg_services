require(File.join(File.dirname(__FILE__), '../spec_helper'))

module CgLookupClient

  describe Entry do

    def create_endpoint(uri, version)
      endpoint = RestEndpoint.new(uri, version)
      endpoint.stub(:register) do |entry, block|
        if entry.id == nil
          # register
          entry.id = Time.now.usec
        end
        block.call(entry.id, true, "ok")
        entry
      end
      endpoint.stub(:lookup) do |type_name, version|
        [{:entry=>Entry.new({:id=>Time.now.usec, :type_name=> "Testing",
                    :version=>"1",
                    :description=>'Desc', :uri=>'http://localhost:3000/'}),
                             :message=>"OK"},
         {:entry=>Entry.new({:id=>Time.now.usec, :type_name=> "Testing",
                    :version=>"1",
                    :description=>'Desc', :uri=>'http://localhost:3000/'}),
                             :message=>"OK"},
         {:entry=>Entry.new({:id=>Time.now.usec, :type_name=> "Testing",
                    :version=>"2",
                    :description=>'Desc', :uri=>'http://localhost:3000/'}),
                             :message=>"OK"}]
      end
      endpoint
    end

    describe "#initialize" do
      it "should ensure a trailing slash on the uri attribute" do
        e = Entry.new({:type_name=>'type_name', :version=>'1',
                       :description=>'Desc', :uri=>'http://localhost:3000'})
        e.uri[-1].chr.should == '/'
      end

      it "should not add a trailing slash to the uri attribute if one exists" do
        e = Entry.new({:type_name=>'type_name', :version=>'1',
                       :description=>'Desc', :uri=>'http://localhost:3000/'})
        e.uri[-2].chr.should_not == '/'
      end
    end

    describe "#configure_endpoint" do

      before(:each) do
        Entry.clear_endpoints
        @endpoint_1 = create_endpoint('http://localhost:5001', '1')
        # Although 1 and 1_dup are separate objects, they are the same from an
        # identity perspective since they have the same server,
        # port and version.
        @endpoint_1_dup = create_endpoint('http://localhost:5001', '1')
        @endpoint_2 = create_endpoint('http://localhost:5002', '1')
        @endpoint_unsupported = create_endpoint('http://localhost:5002', '2')
      end

      it "should configure a default endpoint" do
        Entry.configure_endpoint
        Entry.endpoints.size.should == 1
      end

      it "should configure a given endpoint" do
        Entry.configure_endpoint(@endpoint_1)
        Entry.endpoints.size.should == 1
      end

      it "should allow for multiple endpoints to be configured" do
        Entry.configure_endpoint(@endpoint_1)
        Entry.configure_endpoint(@endpoint_2)
        Entry.endpoints.size.should == 2
      end

      it "should not allow duplicate endpoints to be configured" do
        Entry.configure_endpoint(@endpoint_1)
        Entry.configure_endpoint(@endpoint_1)
        Entry.configure_endpoint(@endpoint_1_dup)
        Entry.endpoints.size.should == 1
      end

      it "should prevent unsupported endpoints from being configured" do
        lambda { Entry.configure_endpoint(@endpoint_unsupported)}.should
        raise_error(UnsupportedEndpointVersionError)
      end
    end

    describe "#clear_endpoint" do
      it "should remove all configured endpoints" do
        Entry.configure_endpoint
        Entry.clear_endpoints
        Entry.endpoints.size.should == 0
      end
    end

    describe "#register" do

      before(:each) do
        Entry.clear_endpoints
        Entry.clear_entries

        @entry = Entry.new({:type_name=>'Type', :version=>'1',
                            :description=>'Desc', :uri=>'http://localhost:3000/'})

        Entry.configure_endpoint(create_endpoint("http://localhost:5000/", "1"))
        Entry.configure_endpoint(create_endpoint("http://localhost:5001/", "1"))

        #Entry.configure_endpoint(RestEndpoint.new("http://localhost:5000/","1"))
      end

      it "should register entries with all configured endpoints" do
        Entry.endpoints.size.should == 2
        registered = @entry.register
        registered.size.should == 2
      end

      it "should not register duplicate entries twice" do
        Entry.endpoints.size.should == 2
        entry_one = Entry.new({:type_name=>'NewType', :version=>'1',
                               :description=>'Desc', :uri=>'http://localhost:3000/'})
        entry_two = Entry.new({:type_name=>'NewType', :version=>'1',
                               :description=>'Desc', :uri=>'http://localhost:3000/'})
        entry_one.should.eql? entry_two
        registered = entry_one.register
        registered.size.should == 2 # with 2 endpoints, this means only 1 entry was registered

        registered = entry_two.register
        registered.size.should == 2 # with 2 endpoints, this means only 1 entry was registered
        Entry.entries.size.should == 1 # number of live entries for registration
      end

      it "should validate that entry attributes are present" do
        Entry.endpoints.size.should == 2
        entry_one = Entry.new({:type_name=>'', :version=>'1',
                               :description=>'Desc', :uri=>'http://localhost:3000/'})
        registered = entry_one.register
        registered.size.should == 0

        entry_one = Entry.new({:type_name=>'Type', :version=>'',
                               :description=>'Desc', :uri=>'http://localhost:3000/'})
        registered = entry_one.register
        registered.size.should == 0

        entry_one = Entry.new({:type_name=>'Type', :version=>'1',
                               :description=>'', :uri=>'http://localhost:3000/'})
        registered = entry_one.register
        registered.size.should == 0

        entry_one = Entry.new({:type_name=>'Type', :version=>'1',
                               :description=>'Desc', :uri=>''})
        registered = entry_one.register
        registered.size.should == 0
      end

    end

    describe "#lookup" do

      before(:each) do
        Entry.clear_endpoints
        Entry.clear_entries

        Entry.configure_endpoint(create_endpoint("http://localhost:5000/", "1"))
        Entry.configure_endpoint(create_endpoint("http://localhost:5001/", "1"))
      end

      it "should lookup an entry that matches on type and version" do
        results = Entry.lookup("Testing","1")

        results.size.should >= 1
        result = results[0]
        result[:entry].type_name.should == "Testing"
        result[:entry].version.should == "1"
        result[:entry].uri.should == 'http://localhost:3000/'
      end

    end

  end

end
