require 'spec_helper'

describe Okey::Server do
  # describe "initialize" do
    # before(:each) do
      # Sudokill::Controller.stub!(:create!).and_return("controller")
    # end
    # it "should set defaults" do
      # server = Sudokill::Server.new
      # server.env.should == :test
      # server.host.should == '0.0.0.0'
      # server.port.should == 44444
      # server.ws_host.should == '0.0.0.0'
      # server.ws_port.should == 8080
      # server.http_port.should == 4567
# 
      # server.max_time_websocket.should == 600
      # server.max_time_socket.should == 120
    # end
#     
    # it "should accept options" do
      # server = Sudokill::Server.new({
        # :env => :development,
        # :host => 'localhost',
        # :port => 454545,
        # :ws_host => '127.0.0.1',
        # :ws_port => 48080,
        # :http_port => 45678,
        # :max_time_websocket => 500,
        # :max_time_socket => 100
      # })
      # server.env.should == :development
      # server.host.should == 'localhost'
      # server.port.should == 454545
      # server.ws_host.should == '127.0.0.1'
      # server.ws_port.should == 48080
      # server.http_port.should == 45678
# 
      # server.max_time_websocket.should == 500
      # server.max_time_socket.should == 100
    # end
  # end
  
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
    # it "should stop the eventmachine" do
      # @server.controller.should_receive(:close)
      # @server.stop_server
    # end
  end
end