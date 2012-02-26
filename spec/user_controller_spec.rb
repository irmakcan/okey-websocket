require 'spec_helper'

describe Okey::UserController do
  before(:each) do
    @controller = Okey::UserController.new
    @user = Okey::User.new()

  end

  # describe "subscribe" do
  # it "should overwrite onmessage block" do
  # @controller.subscribe(@user)
  # @user.websocket.onmessage.should be_instance_of(Proc)
  # end
  # end

  describe "authenticate" do
    describe "failure" do
      it "should fail on different version"
    end

    describe "success" do
      it "should assign user's username"
    end

  end
end