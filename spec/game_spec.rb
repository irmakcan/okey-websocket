require 'spec_helper'

describe Okey::Game do
  include EventMachine::SpecHelper

  describe "initialization" do

    before(:each) do
      em {
        @channel = EventMachine::Channel.new
        @user = Okey::User.new(FakeWebSocketClient.new({}))
        @table = Okey::Table.new
        @table.add_user(@user)
        done
      }
    end

    it "should set default values" do
      em{
        game = Okey::Game.new(@channel, @table)
        game.instance_variable_get(:@channel).should == @channel
        game.instance_variable_get(:@table).should == @table
        Okey::Chair::POSITIONS.should include(game.instance_variable_get(:@turn))
        game.instance_variable_get(:@tile_bag).should be_instance_of(Okey::TileBag)
        done
      }
    end

    it "should send game starting message with game information" do
      em {
        game = Okey::Game.new(@channel, @table)
        json = @user.websocket.sent_data
        json.should_not be_nil
        parsed = JSON.parse(json)

        parsed['action'].should == 'game_start'
        parsed['turn'].to_sym.should == game.instance_variable_get(:@turn)
        parsed['center_count'].to_i.should == game.instance_variable_get(:@tile_bag).center_tile_left
        parsed['hand'].should be_instance_of(Array)
        parsed['hand'].should have_at_least(14).things
        parsed['hand'].should have_at_most(15).things
        parsed['indicator'].should == game.instance_variable_get(:@tile_bag).indicator.to_s

        done
      }
    end

  end

  describe "actions" do

    before(:each) do
      em {
        @channel = EventMachine::Channel.new
        @users = []

        user = Okey::User.new(FakeWebSocketClient.new({}))
        user.username = "user 1"
        @users << user
        user = Okey::User.new(FakeWebSocketClient.new({}))
        user.username = "user 2"
        @users << user
        user = Okey::User.new(FakeWebSocketClient.new({}))
        user.username = "user 3"
        @users << user
        user = Okey::User.new(FakeWebSocketClient.new({}))
        user.username = "user 4"
        @users << user

        @table = Okey::Table.new
        @users.each do |usr| 
          @table.add_user(usr) 
          user.sid = @channel.subscribe { |msg| user.websocket.send msg }
        end

        @game = Okey::Game.new(@channel, @table)
        done
      }
    end

    describe "throw tile" do

      describe "failure" do

        it "should return error message if the turn is not user's turn" do
          em {
            turn = @game.instance_variable_get(:@turn)
            user = nil
            @users.each { |usr| user = usr; break if usr.position != turn }
            hand = @game.instance_variable_get(:@tile_bag).hands[user.position]
            msg = @game.throw_tile(user, hand[0])
            msg.should_not == nil

            done
          }

        end

        it "should return error message if the user has not possess the tile" do
          em {
            turn = @game.instance_variable_get(:@turn)
            hand = @game.instance_variable_get(:@tile_bag).hands[turn]
            tile = nil
            tile_factory = Okey::TileFactory.instance
            (1..13).each do |i|
              tile = tile_factory.get(i, 1)
              break unless hand.include?(tile)
            end
            msg = @game.throw_tile(@table.chairs[turn], tile)
            msg.should_not == nil

            done
          }
        end

      end
      
      describe "success" do

        it "should return nil" do
          em {
            turn = @game.instance_variable_get(:@turn)
            hand = @game.instance_variable_get(:@tile_bag).hands[turn]
            msg = @game.throw_tile(@table.chairs[turn], hand[0])
            msg.should == nil
            done
          }
        end
        
        it "should change the turn to next" do
          em {
            turn = @game.instance_variable_get(:@turn)
            hand = @game.instance_variable_get(:@tile_bag).hands[turn]
            @game.throw_tile(@table.chairs[turn], hand[0])
            new_turn = @game.instance_variable_get(:@turn)
            new_turn.should_not == turn
            Okey::Chair::next(turn).should == new_turn
            done
          }
        end
        
        it "should push a message to the channel" do
          em {
            @channel.should_receive(:push)
            turn = @game.instance_variable_get(:@turn)
            hand = @game.instance_variable_get(:@tile_bag).hands[turn]
            @game.throw_tile(@table.chairs[turn], hand[0])
            done
          }
        end
        
      end

    end
    
    describe "throw to finish" do
      
      describe "failure" do

        it "should return error message if the turn is not user's turn" do
          # em {
            # turn = @game.instance_variable_get(:@turn)
            # user = nil
            # @users.each { |usr| user = usr; break if usr.position != turn }
            # hand = @game.instance_variable_get(:@tile_bag).hands[user.position]
            # msg = @game.throw_to_finish(user, hand[0])
            # msg.should_not == nil
# 
            # done
          # }

          # em {
            # tile_bag = Okey::TileBag.new
            # tile_bag.distibute_tiles({:south => nil, :east => nil, :west => nil, :north => nil}, :south)
            # hand = tile_bag.hands[:south]
            # p hand
            # hand.sort! { |a,b| 
              # comp = (a.value <=> b.value)
              # comp.zero? ? a.color <=> b.color : comp
            # }
            # p hand
            # done
          # }
        end

        # it "should return error message if the user has not possess the tile" do
          # em {
            # turn = @game.instance_variable_get(:@turn)
            # hand = @game.instance_variable_get(:@tile_bag).hands[turn]
            # tile = nil
            # tile_factory = Okey::TileFactory.instance
            # (1..13).each do |i|
              # tile = tile_factory.get(i, 1)
              # break unless hand.include?(tile)
            # end
            # msg = @game.throw_tile(@table.chairs[turn], tile)
            # msg.should_not == nil
# 
            # done
          # }
        # end
# 
      end
#       
      # describe "success" do
# 
        # it "should return nil" do
          # em {
            # turn = @game.instance_variable_get(:@turn)
            # hand = @game.instance_variable_get(:@tile_bag).hands[turn]
            # msg = @game.throw_tile(@table.chairs[turn], hand[0])
            # msg.should == nil
            # done
          # }
        # end
#         
        # it "should change the turn to next" do
          # em {
            # turn = @game.instance_variable_get(:@turn)
            # hand = @game.instance_variable_get(:@tile_bag).hands[turn]
            # @game.throw_tile(@table.chairs[turn], hand[0])
            # new_turn = @game.instance_variable_get(:@turn)
            # new_turn.should_not == turn
            # Okey::Chair::next(turn).should == new_turn
            # done
          # }
        # end
#         
        # it "should push a message to the channel" do
          # em {
            # @channel.should_receive(:push)
            # turn = @game.instance_variable_get(:@turn)
            # hand = @game.instance_variable_get(:@tile_bag).hands[turn]
            # @game.throw_tile(@table.chairs[turn], hand[0])
            # done
          # }
        # end
#         
      # end
      
    end
    
    describe "draw tile" do
      
      describe "failure" do

        it "should return error message if the turn is not user's turn" do
          em {
            turn = @game.instance_variable_get(:@turn)
            user = nil
            @users.each { |usr| user = usr; break if usr.position != turn }
            hand = @game.instance_variable_get(:@tile_bag).hands[user.position]
            msg = @game.draw_tile(user, true)
            msg.should_not == nil

            done
          }

        end

        it "should return error message if there is no tile on left" do
          em {
            turn = @game.instance_variable_get(:@turn)
            msg = @game.draw_tile(@table.chairs[turn], false) # draw left tile
            msg.should_not == nil
            done
          }
        end
        
        it "should return error message if there is no tile on center" do
          em {
            turn = @game.instance_variable_get(:@turn)
            msg = @game.draw_tile(@table.chairs[turn], true) # draw center tile
            msg.should_not == nil
            done
          }
        end

      end
      
      describe "success" do

        it "should return nil if draw center tile successes" do
          em {
            @game.instance_variable_set(:@turn, :east)
            turn = @game.instance_variable_get(:@turn)
            msg = @game.draw_tile(@table.chairs[turn], true) # draw center tile
            msg.should == nil
            done
          }
        end
        
        it "should return nil if draw left tile successes" do
          em {
            turn = @game.instance_variable_get(:@turn)
            hand = @game.instance_variable_get(:@tile_bag).hands[turn]
            @game.throw_tile(@table.chairs[turn], hand[0]) # tile thrown 
            
            turn = @game.instance_variable_get(:@turn)
            msg = @game.draw_tile(@table.chairs[turn], false) # draw center tile
            msg.should == nil
            done
          }
        end
        
        it "should push a message to the channel" do
          em {
            
            turn = @game.instance_variable_get(:@turn)
            hand = @game.instance_variable_get(:@tile_bag).hands[turn]
            @game.throw_tile(@table.chairs[turn], hand[0]) # tile thrown 
            
            @channel.should_receive(:push)
            turn = @game.instance_variable_get(:@turn)
            msg = @game.draw_tile(@table.chairs[turn], false) # draw center tile
            msg.should == nil
            done
          }
        end
        
      end
      
    end

  end

end