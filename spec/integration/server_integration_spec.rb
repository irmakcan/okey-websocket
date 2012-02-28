require 'spec_helper'
require 'json'

describe Okey::Server do
  include EventMachine::SpecHelper

  before(:each) do
    Okey::WebServer.stub!(:run!)
  end

  it "should fail on non WebSocket request" do
    em {
      EventMachine.add_timer(0.1) do
        http = EventMachine::HttpRequest.new('http://127.0.0.1:12345/').get :timeout => 0
        http.errback { done }
        http.callback { fail }
      end

      server = Okey::Server.new(:host => "0.0.0.0", :wsport => 12345)
      server.start
    }
  end

  

end