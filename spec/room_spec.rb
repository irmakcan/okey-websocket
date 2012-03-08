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
        #@user.websocket.get_onclose.should_not == nil TODO
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
    
    it "should set user's position" do
      em {
        @room.join_room(@user)
        @user.position.should_not be_nil
        done
      }
    end
    
    it "should initialize the game if the room is full" do
      em {
        @room.join_room(@user)
        
        user1 = Okey::User.new(FakeWebSocketClient.new({}))
        user2 = Okey::User.new(FakeWebSocketClient.new({}))
        user3 = Okey::User.new(FakeWebSocketClient.new({}))

        @room.join_room(user1)
        @room.join_room(user2)
        Okey::Game.should_receive(:new).with(@room.instance_variable_get(:@room_channel), @room.instance_variable_get(:@table))
        @room.join_room(user3)
        
        done
      }
    end
    
    it "should send a success message with users positions" do
      em {
        @room.join_room(@user)
        json = @user.websocket.sent_data
        parsed = JSON.parse(json)
        
        parsed['action'].should == 'join_room'
        Okey::Chair::POSITIONS.should include(parsed['position'].to_sym)
        parsed['users'].should be_instance_of(Array)
        
        done
      }
    end
    
    it "should send a new_user message when a new user is joined" do
      em {
        @room.join_room(@user)
        @user.websocket.sent_data = nil
        
        user1 = Okey::User.new(FakeWebSocketClient.new({}))
        user1.username = "new user"
        @room.join_room(user1)
        
        json = @user.websocket.sent_data
        parsed = JSON.parse(json)
        
        parsed['action'].should == 'new_user'
        Okey::Chair::POSITIONS.should include(parsed['position'].to_sym)
        parsed['username'].should == user1.username

        done
      }
    end
    
    # it "should replace the AI with the new user"
    
  end
  
  describe "leave" do
    
    before(:each) do
      @room_name = "new room"
      @user = Okey::User.new(FakeWebSocketClient.new({}))
      @room = Okey::Room.new(Okey::Lounge.new(Okey::UserController.new), @room_name)
      @user.username = 'example_user'
    end
    
    it "should inform the channel" do
      em {
        @room.join_room(@user)
        user1 = Okey::User.new(FakeWebSocketClient.new({}))
        @room.join_room(user1)
        @user.websocket.sent_data = nil
        @room.leave_room(user1)
        json = @user.websocket.sent_data
        parsed = JSON.parse(json)
        
        parsed['action'].should == 'user_leave'
        parsed['position'].to_sym.should == user1.position
        parsed['replaced_username'].should == "AI" # TODO
        done
      }
    end
    
    it "should add AI if the game is already started"
    
    it "should add user to lounge" do
      em {
        @room.join_room(@user)
        @room.instance_variable_get(:@lounge).should_receive(:join_lounge).with(@user)
        @room.leave_room(@user)
        
        done
      }
    end
    
    it "should unsubscribe user's sid from channel" do
      em {
        @room.join_room(@user)
        room_channel = @room.instance_variable_get(:@room_channel)
        room_channel.should_receive(:unsubscribe).with(@user.sid)
        @room.leave_room(@user)
        done
      }
    end
    
    it "should remove user from the table" do
      em {
        @room.join_room(@user)
        table = @room.instance_variable_get(:@table)
        table.should_receive(:remove).with(@user.position)
        @room.leave_room(@user)
        done
      }
    end
    
    it "should destroy the room from the lounge if empty" do
      em {
        @room.join_room(@user)
        lounge = @room.instance_variable_get(:@lounge)
        lounge.should_receive(:destroy_room).with(@room)
        @room.leave_room(@user)
        done
      }
    end
    
  end
  
  describe "messaging" do
    
  end
  
end