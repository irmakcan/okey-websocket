require 'spec_helper'

describe Okey::Lounge do
  include EventMachine::SpecHelper


  describe "initialization" do

    it "should have default values" do
      em {
        lounge = Okey::Lounge.new
        lounge.instance_variable_get(:@player_count).should == 0
        lounge.instance_variable_get(:@lounge_channel).should be_instance_of(EventMachine::Channel)
        lounge.instance_variable_get(:@empty_rooms).should == []
        lounge.instance_variable_get(:@full_rooms).should == []

        done
      }
    end
    
    it "should add periodic timer with value 5" do
      em {
        EventMachine.should_receive(:add_periodic_timer).with(5)
        Okey::Lounge.new
        done
      }
    end
  end
  
  describe "periodic timer (updater)" do
      
  end
  
  describe "join" do
    before(:each) do
      @user = Okey::User.new(FakeWebSocketClient.new({}))
      #@join_json_attr = { :action => 'authenticate', :payload => { :version => '0.0.0', :username => 'irmak', :salt => 'qwerty' }}
      #@create_json_attr = { :action => 'authenticate', :payload => { :version => '0.0.0', :username => 'irmak', :salt => 'qwerty' }}
    end
    it "should send success json"
    it "should increase the player count by one" do
      em {
        @lounge = Okey::Lounge.new
        count = @lounge.instance_variable_get(:@player_count)
        @lounge.join_lounge(@user)
        @lounge.instance_variable_get(:@player_count).should == count + 1
        done
      }
    end
    it "should change websocket procs" do
      em {
        @lounge = Okey::Lounge.new
        onmessage = @user.websocket.get_onmessage
        onclose = @user.websocket.get_onclose
        onerror = @user.websocket.get_onerror
        @lounge.join_lounge(@user)
        @user.websocket.get_onmessage.should_not == onmessage
        # @user.websocket.get_onclose.should_not == onclose TODO
        # @user.websocket.get_onerror.should_not == onerror TODO

        done
      }
    end
  end

end