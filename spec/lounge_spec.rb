require 'spec_helper'

describe Okey::Lounge do
  include EventMachine::SpecHelper

  describe "initialization" do

    it "should have default values" do
      em {
        lounge = Okey::Lounge.new(Okey::UserController.new)
        lounge.instance_variable_get(:@players).should be_instance_of(Set)
        lounge.instance_variable_get(:@empty_rooms).should == {}
        lounge.instance_variable_get(:@full_rooms).should == {}
        done
      }
    end

  end

  describe "join lounge" do

    before(:each) do
      @user = Okey::User.new(FakeWebSocketClient.new({}))
    end

    it "should send join_lounge json" do
      em {
        Okey::Lounge.new(Okey::UserController.new).join_lounge(@user)
        # @user.websocket.get_onmessage.call("")

        json = @user.websocket.sent_data
        parsed = JSON.parse(json)
        parsed["status"].should == "join_lounge"
        parsed["points"].should be_a_kind_of(Integer)

        done
      }
    end

    it "should increase the player count by one" do
      em {
        @lounge = Okey::Lounge.new(Okey::UserController.new)
        count = @lounge.instance_variable_get(:@players).length
        @lounge.join_lounge(@user)
        @lounge.instance_variable_get(:@players).length.should == count + 1
        done
      }
    end
    
    it "should not increase the number of users on double join" do
      em {
        @lounge = Okey::Lounge.new(Okey::UserController.new)
        count = @lounge.instance_variable_get(:@players).length
        @lounge.join_lounge(@user)
        @lounge.join_lounge(@user)
        @lounge.instance_variable_get(:@players).length.should == count + 1
        done
      }
    end

    it "should change websocket procs" do
      em {
        @lounge = Okey::Lounge.new(Okey::UserController.new)
        onmessage = @user.websocket.get_onmessage
        onclose = @user.websocket.get_onclose
        # onerror = @user.websocket.get_onerror
        @lounge.join_lounge(@user)
        @user.websocket.get_onmessage.should_not == onmessage
        @user.websocket.get_onclose.should_not == onclose
        # @user.websocket.get_onerror.should_not == onerror TODO

        done
      }
    end

  end
  
  describe "leave lounge" do
    
    it "should remove the user from the users set" do
      em {
        user = Okey::User.new(FakeWebSocketClient.new({}))
        lounge = Okey::Lounge.new(Okey::UserController.new)
        lounge.join_lounge(user)
        user_count = lounge.instance_variable_get(:@players).length
        lounge.leave_lounge(user)
        lounge.instance_variable_get(:@players).length.should == user_count - 1
        done
      }
    end
    
  end
  
  describe "destroy room" do
    
    before(:each) do
      @user = Okey::User.new(FakeWebSocketClient.new({}))
    end
    
    it "should delete room from one of the hashes" do
      @lounge = Okey::Lounge.new(Okey::UserController.new)
      room = Okey::Room.new(@lounge, "room_name")
      @lounge.instance_variable_set(:@empty_rooms, { room.name => room })
      er = @lounge.instance_variable_get(:@empty_rooms)
      @lounge.destroy_room(room)
      er.should be_empty
    end
    
  end

  describe "messaging" do

    before(:each) do
      @user = Okey::User.new(FakeWebSocketClient.new({}))
      @refresh_request_attr = { :action => 'refresh_list' }
      @create_json_attr = { :action => 'create_room', :room_name => 'new room'}
      @join_json_attr = { :action => 'join_room', :room_name => 'room1'}
      @leave_request_attr = { :action => 'leave_lounge' }
      @lounge = Okey::Lounge.new(Okey::UserController.new)
      @lounge.join_lounge(@user)
      @user.websocket.sent_data = nil
    end

    describe "undefined request" do

      it "should send error json on empty string" do
        em {
          @user.websocket.get_onmessage.call("")
          json = @user.websocket.sent_data
          parsed = JSON.parse(json)

          parsed["status"].should == "error"
          parsed["message"].should == "Messaging error"

          done
        }
      end

      it "should send error json on empty json" do
        em {
          @user.websocket.get_onmessage.call({}.to_json)
          json = @user.websocket.sent_data
          parsed = JSON.parse(json)

          parsed["status"].should == "error"
          parsed["message"].should == "Messaging error"

          done
        }
      end

      it "should send error json on undefined request" do
        em {
          @user.websocket.get_onmessage.call({ :dummy_request => :val }.to_json)
          json = @user.websocket.sent_data
          parsed = JSON.parse(json)

          parsed["status"].should == "error"
          parsed["message"].should == "Messaging error"

          done
        }
      end

    end

    describe "leave request" do

      it "should decrease the online players count by one" do
        em {
          count = @lounge.instance_variable_get(:@players).length
          @user.websocket.get_onmessage.call(@leave_request_attr.to_json)
          @lounge.instance_variable_get(:@players).length.should == count - 1
          done
        }
      end

      it "should subscribe to user controller and change the websocket procs" do
        em {
          onmessage = @user.websocket.get_onmessage
          # onclose = @user.websocket.get_onclose
          # onerror = @user.websocket.get_onerror
 
          @user.websocket.get_onmessage.call(@leave_request_attr.to_json)

          @user.websocket.get_onmessage.should_not == onmessage
          done
        }
      end

    end

    describe "update request" do

      it "should send appropriate json" do
        em {
          @user.websocket.get_onmessage.call(@refresh_request_attr.to_json)
          json = @user.websocket.sent_data
          parsed = JSON.parse(json)

          parsed["status"].should == "lounge_update"
          parsed["list"].should be_instance_of(Array)
          parsed["player_count"].to_i.should == @lounge.instance_variable_get(:@players).length
          done
        }
      end

    end

    describe "join room request" do

      describe "success" do

        it "should join the user in" do
          em {
            user1 = Okey::User.new(FakeWebSocketClient.new({}))
            @lounge.join_lounge(user1)
            user1.websocket.get_onmessage.call((@create_json_attr).to_json) # create room

            rooms = @lounge.instance_variable_get(:@empty_rooms)
            room = rooms[@create_json_attr[:room_name]]
            room.should_receive(:join_room).with(@user)

            @join_json_attr.merge!({ :room_name => @create_json_attr[:room_name] })
            @user.websocket.get_onmessage.call((@join_json_attr).to_json) # join request

            done
          }
        end

      end

      describe "failure" do

        it "should return error json if the room is full" do
          em {
            user1 = Okey::User.new(FakeWebSocketClient.new({}))
            user2 = Okey::User.new(FakeWebSocketClient.new({}))
            user3 = Okey::User.new(FakeWebSocketClient.new({}))
            user4 = Okey::User.new(FakeWebSocketClient.new({}))

            @lounge.join_lounge(user1)
            @lounge.join_lounge(user2)
            @lounge.join_lounge(user3)
            @lounge.join_lounge(user4)
            user1.websocket.get_onmessage.call((@create_json_attr).to_json) # create room

            @join_json_attr.merge!({ :room_name => @create_json_attr[:room_name] })
            user2.websocket.get_onmessage.call((@join_json_attr).to_json) # join room
            user3.websocket.get_onmessage.call((@join_json_attr).to_json) # join room
            user4.websocket.get_onmessage.call((@join_json_attr).to_json) # join room

            @user.websocket.get_onmessage.call((@join_json_attr).to_json) # join room
            json = @user.websocket.sent_data
            parsed = JSON.parse(json)

            parsed["status"].should == "error"
            parsed["message"].should == "Room is full"
            done
          }
        end

        it "should return error json if the room cannot be found" do
          em {
            @user.websocket.get_onmessage.call((@join_json_attr).to_json) # join room
            json = @user.websocket.sent_data
            parsed = JSON.parse(json)

            parsed["status"].should == "error"
            parsed["message"].should == "Cannot find the room"
            done
          }
        end

      end

      it "should send an error json if the room field is nil or empty" do
        em {
          @user.websocket.get_onmessage.call((@join_json_attr.merge!({ :room_name => "" })).to_json)
          json = @user.websocket.sent_data
          parsed = JSON.parse(json)

          parsed["status"].should == "error"
          parsed["message"].should == "Room name cannot be empty"

          @user.websocket.sent_data = nil
          @join_json_attr.delete(:room_name)
          @user.websocket.get_onmessage.call(@join_json_attr.to_json)
          json = @user.websocket.sent_data
          parsed = JSON.parse(json)

          parsed["status"].should == "error"
          parsed["message"].should == "Room name cannot be empty"
          done
        }
      end

    end

    describe "create room request" do

      describe "success" do

        it "should create a new room and merge it to the empty room hash" do
          em {
            empty_rooms_length = @lounge.instance_variable_get(:@empty_rooms).length
            @user.websocket.get_onmessage.call((@create_json_attr).to_json)
            empty_rooms = @lounge.instance_variable_get(:@empty_rooms)
            empty_rooms.length.should == empty_rooms_length + 1
            empty_rooms[@create_json_attr[:room_name]].should be_instance_of(Okey::Room)
            done
          }
        end

      end

      describe "failure" do

        it "should send error json if the room name is already in the list" do
          em {
            user1 = Okey::User.new(FakeWebSocketClient.new({}))
            @lounge.join_lounge(user1)
            user1.websocket.get_onmessage.call((@create_json_attr).to_json) # create room

            @user.websocket.get_onmessage.call(@create_json_attr.to_json) # try to create second
            json = @user.websocket.sent_data
            parsed = JSON.parse(json)

            parsed["status"].should == "error"
            parsed["message"].should == "Room name is already taken"

            done
          }
        end

        it "should send an error json if the room field is nil or empty or blank" do
          em {
            # empty
            @user.websocket.get_onmessage.call((@create_json_attr.merge!({ :room_name => "" })).to_json)
            json = @user.websocket.sent_data
            parsed = JSON.parse(json)

            parsed["status"].should == "error"
            parsed["message"].should == "Room name cannot be blank"

            @user.websocket.sent_data = nil
            #nil
            @create_json_attr.delete(:room_name)
            @user.websocket.get_onmessage.call(@create_json_attr.to_json)
            json = @user.websocket.sent_data
            parsed = JSON.parse(json)

            parsed["status"].should == "error"
            parsed["message"].should == "Room name cannot be blank"
            
            @user.websocket.sent_data = nil
            #blank
            @create_json_attr.delete(:room_name)
            @user.websocket.get_onmessage.call((@create_json_attr.merge!({ :room_name => "  " })).to_json)
            json = @user.websocket.sent_data
            parsed = JSON.parse(json)

            parsed["status"].should == "error"
            parsed["message"].should == "Room name cannot be blank"
            done
          }
        end

      end

    end
  end

end