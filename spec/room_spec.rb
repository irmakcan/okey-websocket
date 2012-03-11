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
        @user.websocket.get_onclose.should_not == nil
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
    
    it "should not join the user to lounge if websocket state is 'closed'" do
      em {
        @room.join_room(@user)
        @user.websocket.instance_variable_set(:@state, :closed)
        lounge = @room.instance_variable_get(:@lounge)
        lounge.should_not_receive(:join_lounge).with(@user)
        @room.leave_room(@user)
        done
      }
    end
    
  end
  
  describe "messaging" do
    
    before(:each) do
      em {
        @room_name = "new room"
        @user = Okey::User.new(FakeWebSocketClient.new({}))
        @room = Okey::Room.new(Okey::Lounge.new(Okey::UserController.new), @room_name)
        @room.join_room(@user)
        @user.websocket.sent_data = nil
        done
      }
    end
    
    describe "leave room" do
      
      it "should call leave_room method on leave_room request" do
        em {
          leave_req_attr = { :action => :leave_room }
          @room.should_receive(:leave_room).with(@user)
          @user.websocket.get_onmessage.call(leave_req_attr.to_json)
          done
        }
      end
      
    end
    
    describe "throw_tile" do
      
      before(:each) do
        @throw_tile_req_attr = { :action => :throw_tile, :tile => "2:2" }
      end
      
      describe "failure" do
        
        it "should send error message if tile cannot been properly parsed" do
          em {
            @throw_tile_req_attr.merge!({ :tile => "" })
            game = Okey::Game.new(@room.instance_variable_get(:@room_channel), @room.instance_variable_get(:@table)) 
            @room.instance_variable_set(:@game, game)
            @user.websocket.get_onmessage.call(@throw_tile_req_attr.to_json)
            json = @user.websocket.sent_data
            parsed = JSON.parse(json)
        
            parsed['status'].should == 'error'
            parsed['payload']['message'].should == 'messaging error'
            done
          }
        end
        
        it "should send error message if game was not initialized" do
          em {
            
            @user.websocket.get_onmessage.call(@throw_tile_req_attr.to_json)
            json = @user.websocket.sent_data
            parsed = JSON.parse(json)
        
            parsed['status'].should == 'error'
            parsed['payload']['message'].should == 'messaging error'
            done
          }
        end
        
      end
      
      describe "success" do
        
        it "should call appropriate method of the game" do
          em {
            game = Okey::Game.new(@room.instance_variable_get(:@room_channel), @room.instance_variable_get(:@table)) 
            @room.instance_variable_set(:@game, game)
            game.should_receive(:throw_tile).with(@user, Okey::TileParser.parse(@throw_tile_req_attr[:tile]))
            @user.websocket.get_onmessage.call(@throw_tile_req_attr.to_json)
            done
          }
        end
        
      end
      
    end
    
    describe "throw_to_finish" do
      
      before(:each) do
        @throw_finish_req_attr = { :action => :throw_to_finish, 
          :hand => [["3:1", "2:1", "1:1"], ["4:0", "4:3", "4:1"], ["7:2", "8:2", "9:2", "1:3", "11:2"], ["0:1", "1:0", "1:2"]], 
          :tile => "2:2" }
      end
      
      describe "failure" do
        
        it "should send error message if tile cannot been properly parsed" do
          em {
            @throw_finish_req_attr.merge!({ :tile => "" })
            game = Okey::Game.new(@room.instance_variable_get(:@room_channel), @room.instance_variable_get(:@table)) 
            @room.instance_variable_set(:@game, game)
            @user.websocket.get_onmessage.call(@throw_finish_req_attr.to_json)
            json = @user.websocket.sent_data
            parsed = JSON.parse(json)
        
            parsed['status'].should == 'error'
            parsed['payload']['message'].should == 'messaging error'
            done
          }
        end
        
        it "should send error message if hand cannot been properly parsed" do
          em {
            @throw_finish_req_attr.merge!({ :hand => [""] })
            game = Okey::Game.new(@room.instance_variable_get(:@room_channel), @room.instance_variable_get(:@table)) 
            @room.instance_variable_set(:@game, game)
            @user.websocket.get_onmessage.call(@throw_finish_req_attr.to_json)
            json = @user.websocket.sent_data
            parsed = JSON.parse(json)
        
            parsed['status'].should == 'error'
            parsed['payload']['message'].should == 'messaging error'
            done
          }
        end
        
        it "should send error message if game was not initialized" do
          em {
            
            @user.websocket.get_onmessage.call(@throw_finish_req_attr.to_json)
            json = @user.websocket.sent_data
            parsed = JSON.parse(json)
        
            parsed['status'].should == 'error'
            parsed['payload']['message'].should == 'messaging error'
            done
          }
        end
        
      end
      
      describe "success" do
        
        it "should call appropriate method of the game" do
          em {
            game = Okey::Game.new(@room.instance_variable_get(:@room_channel), @room.instance_variable_get(:@table)) 
            @room.instance_variable_set(:@game, game)
            game.should_receive(:throw_to_finish)
            @user.websocket.get_onmessage.call(@throw_finish_req_attr.to_json)
            done
          }
        end
        
        it "should subscribe users to the lounge if @game.throw_to_finish returns nil" do
          em {
            class FakeGame
              def throw_to_finish(a, b, c) nil end
            end
            
            game = FakeGame.new 
            @room.instance_variable_set(:@game, game)
            @user.websocket.get_onmessage.call(@throw_finish_req_attr.to_json)
            msg = @user.websocket.sent_data
            msg.should_not == nil
            
            done
          }
        end
        
      end
      
    end
    
    describe "draw_tile" do
      
      before(:each) do
        @draw_tile_req_attr = { :action => :draw_tile, :center => true }
      end
      
      describe "failure" do
        
        it "should send error message if center is nil" do
          em {
            @draw_tile_req_attr.delete(:center)
            game = Okey::Game.new(@room.instance_variable_get(:@room_channel), @room.instance_variable_get(:@table)) 
            @room.instance_variable_set(:@game, game)
            @user.websocket.get_onmessage.call(@draw_tile_req_attr.to_json)
            json = @user.websocket.sent_data
            parsed = JSON.parse(json)
        
            parsed['status'].should == 'error'
            parsed['payload']['message'].should == 'messaging error'
            done
          }
        end
        
        it "should send error message if game was not initialized" do
          em {
            
            @user.websocket.get_onmessage.call(@draw_tile_req_attr.to_json)
            json = @user.websocket.sent_data
            parsed = JSON.parse(json)
        
            parsed['status'].should == 'error'
            parsed['payload']['message'].should == 'messaging error'
            done
          }
        end
        
      end
      
      describe "success" do
        
        it "should call appropriate method of the game" do
          em {
            game = Okey::Game.new(@room.instance_variable_get(:@room_channel), @room.instance_variable_get(:@table)) 
            @room.instance_variable_set(:@game, game)
            game.should_receive(:draw_tile).with(@user, @draw_tile_req_attr[:center])
            @user.websocket.get_onmessage.call(@draw_tile_req_attr.to_json)
            done
          }
        end
        
      end
      
    end
    
    #
    describe "undefined request" do

      it "should send error json on empty string" do
        em {
          @user.websocket.get_onmessage.call("")
          json = @user.websocket.sent_data
          parsed = JSON.parse(json)

          parsed["status"].should == "error"
          parsed["payload"]["message"].should == "messaging error"

          done
        }
      end

      it "should send error json on empty json" do
        em {
          @user.websocket.get_onmessage.call({}.to_json)
          json = @user.websocket.sent_data
          parsed = JSON.parse(json)

          parsed["status"].should == "error"
          parsed["payload"]["message"].should == "messaging error"

          done
        }
      end

      it "should send error json on undefined request" do
        em {
          @user.websocket.get_onmessage.call({ :dummy_request => :val }.to_json)
          json = @user.websocket.sent_data
          parsed = JSON.parse(json)

          parsed["status"].should == "error"
          parsed["payload"]["message"].should == "messaging error"

          done
        }
      end

    end
    
  end
  
end