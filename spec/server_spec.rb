require 'spec_helper'

describe Okey::Server do
  describe "initialize" do
    it "should set defaults" do
      server = Okey::Server.new
      server.env.should == :test
      server.host.should == '0.0.0.0'
      server.http_port.should == 3000
      server.ws_host.should == '0.0.0.0'
      server.ws_port.should == 8080
    end

    it "should accept options" do
      server = Okey::Server.new({
        :env => :development,
        :host => 'localhost',
        :ws_host => '127.0.0.1',
        :ws_port => 48080,
        :http_port => 45678,
      })
      server.env.should == :development
      server.host.should == 'localhost'
      server.ws_host.should == '127.0.0.1'
      server.ws_port.should == 48080
      server.http_port.should == 45678

    end
  end

  describe "stop" do
    before(:each) do
      @server = Okey::Server.new
      EventMachine.stub!(:stop)
    # @server.controller = mock(Sudokill::Controller, :close => nil)
    end
    it "should stop the eventmachine" do
      EventMachine.should_receive(:stop)
      @server.stop_server
    end
    
  end
end