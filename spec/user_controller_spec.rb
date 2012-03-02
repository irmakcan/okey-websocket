require 'spec_helper'
require 'json'

describe Okey::UserController do
  include EventMachine::SpecHelper
  # describe "subscribe" do
  # it "should overwrite onmessage block" do
  # @controller.subscribe(@user)
  # @user.websocket.onmessage.should be_instance_of(Proc)
  # end
  # end

  describe "authentication" do
    before(:each) do
      @user = Okey::User.new(FakeWebSocketClient.new({}))
      @json_attr = { :action => 'authenticate', :payload => { :version => '0.0.0', :username => 'irmak', :salt => 'qwerty' }}
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
            parsed["payload"]["message"].should == "messaging error"

            done
          }
        end
        it "should return fail json message on empty json" do
          em {
            @user.websocket.get_onmessage.call({}.to_json)

            json = @user.websocket.sent_data
            parsed = JSON.parse(json)
            parsed["status"].should == "error"
            parsed["payload"]["message"].should == "messaging error"

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
            parsed["payload"]["message"].should == "messaging error"

            done
          }
        end
      end

      it "should return fail json message on different version" do
        em {
          @json_attr[:payload].merge!({:version => '1.1.1'})
          @user.websocket.get_onmessage.call(@json_attr.to_json)

          json = @user.websocket.sent_data
          parsed = JSON.parse(json)
          parsed["status"].should == "error"
          parsed["payload"]["message"].should == "incompatible version"

          done
        }
      end

      #it "should return authentication error message on username, salt mismatch"

      it "should return authentication error message on invalid username" do
        em {
          @json_attr[:payload].merge!({:username => ''})
          @user.websocket.get_onmessage.call(@json_attr.to_json)

          json = @user.websocket.sent_data
          parsed = JSON.parse(json)
          parsed["status"].should == "error"
          parsed["payload"]["message"].should == "authentication error"

          done
        }
      end
      it "should return authentication error message on empty username" do
        em {
          @json_attr[:payload].delete(:username)
          @user.websocket.get_onmessage.call(@json_attr.to_json)

          json = @user.websocket.sent_data
          parsed = JSON.parse(json)
          parsed["status"].should == "error"
          parsed["payload"]["message"].should == "authentication error"

          done
        }
      end

    end

    describe "success" do
      #it "should authenticate on matching username salt pair"

      it "should assign user's username" do
        em {
          old_block = @user.websocket.get_onmessage
          @user.websocket.get_onmessage.call(@json_attr.to_json)
          @user.username.should == @json_attr[:payload][:username]
          
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
      it "should change the onclose Proc"
    end
  end

# describe "authenticate" do
# describe "failure" do
# it "should fail on different version"
# end
#
# describe "success" do
# it "should assign user's username"
# end
#
# end
end