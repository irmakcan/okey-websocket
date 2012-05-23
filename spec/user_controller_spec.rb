require 'spec_helper'
require 'json'

describe Okey::UserController do
  include EventMachine::SpecHelper

  it "should change websocket procs" do
    em {
      @user = Okey::User.new(FakeWebSocketClient.new({}))
      @user.websocket.get_onmessage.should == nil
      @user.websocket.get_onclose.should == nil
      
      controller = Okey::UserController.new
      controller.subscribe(@user)
      
      @user.websocket.get_onmessage.should_not == nil
      @user.websocket.get_onclose.should_not == nil

      done
    }
  end

  describe "authentication" do
    
    before(:each) do
      @user = Okey::User.new(FakeWebSocketClient.new({}))
      @json_attr = { :action => 'authenticate', :version => '0.0.0', :username => 'irmak', :access_token => 'fdhasjk' }
      controller = Okey::UserController.new
      controller.subscribe(@user)
    end

    describe "failure" do
      
      describe "unsupported messages" do
        
        it "should return fail json message on empty string" do
          em {
            @user.websocket.get_onmessage.call("")

            json = @user.websocket.sent_data
            parsed = JSON.parse(json)
            parsed["status"].should == "error"
            parsed["message"].should == "Messaging error"

            done
          }
        end
        
        it "should return fail json message on empty json" do
          em {
            @user.websocket.get_onmessage.call({}.to_json)

            json = @user.websocket.sent_data
            parsed = JSON.parse(json)
            parsed["status"].should == "error"
            parsed["message"].should == "Messaging error"

            done
          }
        end
        
        it "should return fail json message on unsupported message" do
          em {
            @json_attr.merge!({ :action => 'not_authenticate' })
            @user.websocket.get_onmessage.call(@json_attr.to_json)

            json = @user.websocket.sent_data
            parsed = JSON.parse(json)
            parsed["status"].should == "error"
            parsed["message"].should == "Messaging error"

            done
          }
        end
      end

      it "should return fail json message on different version" do
        em {
          @json_attr.merge!({:version => '1.1.1'})
          @user.websocket.get_onmessage.call(@json_attr.to_json)

          json = @user.websocket.sent_data
          parsed = JSON.parse(json)
          parsed["status"].should == "error"
          parsed["message"].should == "Incompatible version"

          done
        }
      end

      it "should return authentication error message on invalid username" do
        em {
          @json_attr.merge!({:username => ''})
          @user.websocket.get_onmessage.call(@json_attr.to_json)

          json = @user.websocket.sent_data
          parsed = JSON.parse(json)
          parsed["status"].should == "error"
          parsed["message"].should == "Authentication error"

          done
        }
      end
      
      it "should return authentication error message on empty username" do
        em {
          @json_attr.delete(:username)
          @user.websocket.get_onmessage.call(@json_attr.to_json)

          json = @user.websocket.sent_data
          parsed = JSON.parse(json)
          parsed["status"].should == "error"
          parsed["message"].should == "Authentication error"

          done
        }
      end

    end

    describe "success" do

      it "should assign user's username" do
        em {
          old_block = @user.websocket.get_onmessage
          @user.websocket.get_onmessage.call(@json_attr.to_json)
          @user.username.should == @json_attr[:username]

          done
        }
      end

      it "should change the onmessage Proc" do
        em {
          old_block = @user.websocket.get_onmessage
          @user.websocket.get_onmessage.call(@json_attr.to_json)
          @user.websocket.get_onmessage.should_not == old_block
          done
        }
      end
      
      it "should change the onclose Proc" do
        em {
          old_block = @user.websocket.get_onclose
          @user.websocket.get_onmessage.call(@json_attr.to_json)
          @user.websocket.get_onclose.should_not == old_block
          done
        }
      end
      
    end
    
  end

end