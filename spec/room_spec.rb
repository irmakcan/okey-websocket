require 'spec_helper'


describe Okey::Room do
  include EventMachine::SpecHelper
  
  describe "initialization" do
    before(:each) do
      @room_name = "new room"
      @user = Okey::User.new(FakeWebSocketClient.new({}))
      @room = Okey::Room.new(Okey::Lounge.new(Okey::UserController.new), @room_name)
    end
    it "should set default values" do
      em{
        @room.instance_variable_get(:@table).should be_instance_of(Okey::Table)
        @room.instance_variable_get(:@name).should == @room_name
        @room.instance_variable_get(:@room_channel).should be_instance_of(EventMachine::Channel)
        done
      }
    end
    
    # it "should join the user in and change its websocket procs" do
      # em {
        # @room
        # @user.websocket.get_onmessage.should_not == nil
        # #@user.websocket.get_onclose.should_not == nil
        # done
      # }
    # end
    
    
    
  end
  
  describe "join" do
    
    before(:each) do
      @room_name = "new room"
      @user = Okey::User.new(FakeWebSocketClient.new({}))
      @room = Okey::Room.new(Okey::Lounge.new(Okey::UserController.new), @room_name)
    end
    
    it "should change user's procs" do
      em {
        @room.join_room(@user)
        @user.websocket.get_onmessage.should_not == nil
        #@user.websocket.get_onclose.should_not == nil
        done
      }
    end
    
    it "should subscribe user to the channel and set its sid" do
      em {
        room_channel = @room.instance_variable_get(:@room_channel)
        room_channel.should_receive(:subscribe)
        @room.join_room(@user)
        done
      }
    end
    
    it "should set user's sid" do
      em {
        @room.join_room(@user)
        @user.sid.should_not be_nil
        done
      }
    end
    
    it "should push message to channel about the new user"
    
    it "should initialize the game if the room is full"
    # it "should send success json" do
      # em {
        # Okey::Lounge.new(Okey::UserController.new('0.0.0')).join_lounge(@user)
        # # @user.websocket.get_onmessage.call("")
# 
        # json = @user.websocket.sent_data
        # parsed = JSON.parse(json)
        # parsed["status"].should == "success"
        # parsed["payload"]["message"].should == "authentication success"
# 
        # done
      # }
    # end
    
  end
  
  describe "leave" do
    
    it "should inform the channel"
    
    it "should add AI if the game is already started"
    
    it "should add user to lounge"
    
    it "should unsubscribe user's sid from channel"
    
    it "should remove user from the table"
    
  end
  
  describe "messaging" do
    
  end
  
end