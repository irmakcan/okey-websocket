require 'spec_helper'


describe Okey::Room do
  include EventMachine::SpecHelper
  
  describe "initialization" do
    
    it "should set default values" do
      em{
        lounge = Okey::Lounge.new(Okey::UserController.new('0.0.0'))
        lounge.instance_variable_get(:@players).should be_instance_of(Set)
        lounge.instance_variable_get(:@empty_rooms).should == {}
        lounge.instance_variable_get(:@full_rooms).should == {}
        done
      }
    end
    
  end
  
end