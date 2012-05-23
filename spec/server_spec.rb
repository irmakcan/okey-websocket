require 'spec_helper'

describe Okey::Server do
  
  describe "initialize" do
    
    it "should set defaults" do
      server = Okey::Server.new
      Okey::Server.env.should == :development
      server.host.should == '0.0.0.0'
      server.http_port.should == 3000
      server.ws_host.should == '0.0.0.0'
      server.ws_port.should == 8080
      Okey::Server.version.should == '0.0.0'
    end

    it "should accept options" do
      server = Okey::Server.new({
        :env => :test,
        :host => 'localhost',
        :ws_host => '127.0.0.1',
        :ws_port => 48080,
        :http_port => 45678,
        :version => '0.1.1'
      })
      Okey::Server.env.should == :test
      server.host.should == 'localhost'
      server.ws_host.should == '127.0.0.1'
      server.ws_port.should == 48080
      server.http_port.should == 45678
      Okey::Server.version.should == '0.1.1'
    end
    
  end

  describe "stop" do
    
    before(:each) do
      @server = Okey::Server.new
      EventMachine.stub!(:stop)
    end
    
    it "should stop the eventmachine" do
      EventMachine.should_receive(:stop)
      @server.stop_server
    end
    
  end
  
end