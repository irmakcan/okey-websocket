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

  end

  describe "join lounge" do
    before(:each) do
      @user = Okey::User.new(FakeWebSocketClient.new({}))
    #@join_json_attr = { :action => 'authenticate', :payload => { :version => '0.0.0', :username => 'irmak', :salt => 'qwerty' }}
    #@create_json_attr = { :action => 'authenticate', :payload => { :version => '0.0.0', :username => 'irmak', :salt => 'qwerty' }}
    end
    it "should send success json" do
      em {
        Okey::Lounge.new.join_lounge(@user)
        # @user.websocket.get_onmessage.call("")

        json = @user.websocket.sent_data
        parsed = JSON.parse(json)
        parsed["status"].should == "success"
        parsed["payload"]["message"].should == "authentication success"

        done
      }
    end
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

  describe "messaging" do
    before(:each) do
      @user = Okey::User.new(FakeWebSocketClient.new({}))
      @refresh_request_attr = { :action => 'refresh_list' }
      #@create_json_attr = { :action => 'authenticate', :payload => { :version => '0.0.0', :username => 'irmak', :salt => 'qwerty' }}
      @lounge = Okey::Lounge.new
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
    describe "update request" do
      it "should send appropriate json" do
        em {
          @user.websocket.get_onmessage.call(@refresh_request_attr.to_json)
          json = @user.websocket.sent_data
          parsed = JSON.parse(json)

          parsed["status"].should == "lounge_update"
          parsed["payload"]["list"].should be_instance_of(Array)

          done
        }
      end
    end
    describe "join room request" do
      ""
    end
    describe "create room request" do
      ""
    end
  end

end