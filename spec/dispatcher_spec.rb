require 'spec_helper'

describe Rory::Dispatcher do
  describe "#redirect" do
    it "redirects to given path if path has scheme" do
      dispatcher = Rory::Dispatcher.new({})
      redirection = dispatcher.redirect('http://example.example')
      redirection[0..1].should == [
        302, {'Content-type' => 'text/html', 'Location'=> 'http://example.example' }
      ]
    end

    it "adds request host and scheme and redirects if path has no scheme" do
      request = {}
      request.stub('scheme' => 'happy', 'host_with_port' => 'somewhere.yay')
      dispatcher = Rory::Dispatcher.new(request)
      redirection = dispatcher.redirect('/example')
      redirection[0..1].should == [
        302, {'Content-type' => 'text/html', 'Location'=> 'happy://somewhere.yay/example' }
      ]
    end
  end

  describe "#dispatch" do
    it "renders a 404 if the requested path is invalid" do
      @request = {}
      @request.stub(:path => nil, :request_method => 'GET')
      @dispatcher = Rory::Dispatcher.new(@request)
      @dispatcher.stub(:get_route).and_return(nil)
      @dispatcher.dispatch[0..1].should == [404, {"Content-type"=>"text/html"}]
    end

    it "instantiates a controller with the parsed request and calls present" do
      @request = {:whatever => :yay}
      @request.stub(:path => '/', :request_method => 'GET')
      @dispatcher = Rory::Dispatcher.new(@request)
      route = { :controller => 'stub' }
      @dispatcher.stub(:get_route).and_return(route)
      @dispatcher.dispatch.should == {
        :whatever => :yay,
        :route => route,
        :dispatcher => @dispatcher,
        :present_called => true # see StubController in /spec/fixture_app
      }
    end
  end

  describe "#get_route" do
    before(:each) do
      @request = {}
      @request.stub(:params => {})
      @dispatcher = Rory::Dispatcher.new(@request)
    end

    it "matches the given path to the routes table" do
      @dispatcher.get_route('/foo', 'put').should == {
        :controller => 'monkeys',
        :action => nil,
        :regex => /^foo$/,
        :methods => [:put]
      }
    end

    it "returns nil if no route found" do
      @dispatcher.get_route('/umbrellas', 'get').should be_nil
    end

    it "returns nil if route found but method is not allowed" do
      @dispatcher.get_route('/foo', 'get').should be_nil
    end

    it "assigns named matches to params hash" do
      @dispatcher.get_route('/this/some-thing_or-other/is/wicked', 'get').inspect.should == {
        :controller => 'awesome',
        :action => 'rad',
        :regex => /^this\/(?<path>[^\/]+)\/is\/(?<very_awesome>[^\/]+)$/,
      }.inspect

      @request.params.should == {:path=>"some-thing_or-other", :very_awesome=>"wicked"}
    end
  end
end
