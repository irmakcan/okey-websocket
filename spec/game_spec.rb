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

        it "should return true" do
          em {
            turn = @game.instance_variable_get(:@turn)
            hand = @game.instance_variable_get(:@tile_bag).hands[turn]
            success = @game.throw_tile(@table.chairs[turn], hand[0])
            success.should == true
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
        
        # it "should push a message to the channel" do
          # em {
            # @channel.should_receive(:push)
            # turn = @game.instance_variable_get(:@turn)
            # hand = @game.instance_variable_get(:@tile_bag).hands[turn]
            # @game.throw_tile(@table.chairs[turn], hand[0])
            # done
          # }
        # end
        
      end

    end
    
    describe "throw to finish" do
      
      describe "failure" do

        it "should return error message if the turn is not user's turn" do
          em {
            turn = @game.instance_variable_get(:@turn)
            user = nil
            @users.each { |usr| user = usr; break if usr.position != turn }
            hand = @game.instance_variable_get(:@tile_bag).hands[user.position]
            msg = @game.throw_to_finish(user, hand, hand[0])
            msg.should_not == nil

            done
          }
        end

        it "should return false if the move is not valid" do
          em {
            class FakeBag
              def throw_tile_center(a, b, c) false end
            end
            turn = @game.instance_variable_get(:@turn)
            hand = @game.instance_variable_get(:@tile_bag).hands[turn]
            @game.instance_variable_set(:@tile_bag, FakeBag.new)
            
            success = @game.throw_to_finish(@table.chairs[turn], nil, nil) # throw_tile_center will return false
            success.should == false

            done
          }
        end

      end
      
      describe "success" do

        it "should return true" do
          em {
            class FakeBag
              def throw_tile_center(a, b, c) true end
            end
            turn = @game.instance_variable_get(:@turn)
            hand = @game.instance_variable_get(:@tile_bag).hands[turn]
            @game.instance_variable_set(:@tile_bag, FakeBag.new)
            
            success = @game.throw_to_finish(@table.chairs[turn], nil, nil) # throw_tile_center will return false
            success.should == true
            done
          }
        end
        
        
        
        # it "should push a message to the channel" do
          # em {
            # class FakeBag
              # def throw_tile_center(a, b, c) true end
            # end
            # turn = @game.instance_variable_get(:@turn)
            # hand = @game.instance_variable_get(:@tile_bag).hands[turn]
            # @game.instance_variable_set(:@tile_bag, FakeBag.new)
            # @channel.should_receive(:push)
            # @game.throw_to_finish(@table.chairs[turn], nil, nil) # throw_tile_center will return false
            # done
          # }
        # end
        
      end
      
    end
    
    describe "draw tile" do
      
      describe "failure" do

        it "should return nil if the turn is not user's turn" do
          em {
            turn = @game.instance_variable_get(:@turn)
            user = nil
            @users.each { |usr| user = usr; break if usr.position != turn }
            hand = @game.instance_variable_get(:@tile_bag).hands[user.position]
            success = @game.draw_tile(user, true)
            success.should == nil

            done
          }

        end

        it "should return nil if there is no tile on left" do
          em {
            turn = @game.instance_variable_get(:@turn)
            success = @game.draw_tile(@table.chairs[turn], false) # draw left tile
            success.should == nil
            done
          }
        end
        
        it "should return nil if there is no tile on center" do
          em {
            turn = @game.instance_variable_get(:@turn)
            success = @game.draw_tile(@table.chairs[turn], true) # draw center tile
            success.should == nil
            done
          }
        end

      end
      
      describe "success" do

        it "should return the tile if draw center tile successes" do
          em {
            @game.instance_variable_set(:@turn, :east)
            turn = @game.instance_variable_get(:@turn)
            tile = @game.draw_tile(@table.chairs[turn], true) # draw center tile
            tile.should be_instance_of(Okey::Tile)
            done
          }
        end
        
        it "should return the tile if draw left tile successes" do
          em {
            turn = @game.instance_variable_get(:@turn)
            hand = @game.instance_variable_get(:@tile_bag).hands[turn]
            t = hand[0]
            @game.throw_tile(@table.chairs[turn], hand[0]) # tile thrown 
            
            turn = @game.instance_variable_get(:@turn)
            tile = @game.draw_tile(@table.chairs[turn], false) # draw center tile  ## TODO
            tile.should be_instance_of(Okey::Tile)
            tile.should == t
            done
          }
        end
        
        # it "should send a message to the channel individually" do
          # em {
            # turn = @game.instance_variable_get(:@turn)
            # hand = @game.instance_variable_get(:@tile_bag).hands[turn]
            # @game.throw_tile(@table.chairs[turn], hand[0]) # tile thrown  
#             
            # turn = @game.instance_variable_get(:@turn)
            # user = @table.chairs[turn]
            # user.websocket.sent_data = nil
            # msg = @game.draw_tile(user, false) # draw center tile ## TODO## TODO
            # msg.should == nil
#             
            # json = user.websocket.sent_data
            # parsed = JSON.parse(json)
            # parsed['action'].should == 'draw_tile'
            # parsed['tile'].should_not == nil
            # parsed['turn'].should == turn.to_s
            # parsed['center_count'].should be_a_kind_of(Fixnum)
#             
            # done
          # }
        # end
        
      end
      
    end

  end

end