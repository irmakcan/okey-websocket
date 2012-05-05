require 'spec_helper'

describe "tiles" do
  
  describe Okey::TileBag do
    
    describe "initialization" do
      
      it "should create 106 tiles" do
        tile_bag = Okey::TileBag.new
        bag = tile_bag.instance_variable_get(:@bag)
        bag.length.should == 106
      end
      
    end
    
    describe "distribute tiles" do
      
    end
    
    describe "finish checkers" do
      
      describe "group checkers" do
        # indicator -> 2:2 => joker -> 3:2 
        before(:all) do
          invalid_groups = [ ["5:0", "5:0", "5:1"], ["5:0", "5:1", "5:2", "5:0"], ["5:0", "3:2", "5:0"], 
                             ["5:0", "6:0", "7:1"], ["5:0", "6:0", "7:0", "8:0", "10:0"], ["13:0", "1:0", "2:0"],
                             ["12:0", "13:0", "1:0", "2:0"], ["13:0", "3:2", "2:0"], ["3:2", "1:1", "2:1"],
                             ["5:3", "3:2", "8:3"], ["12:0", "13:0", "1:0", "3:2"], ["0:1", "0:0", "3:2"],
                             ["3:2", "3:2", "2:1", "3:1"], ["8:0", "8:1", "8:2", "8:1"], ["8:0", "8:1", "8:2", "3:2", "3:2"]]
          valid_sets = [ ["5:0", "5:1", "5:3"], ["13:3", "13:0", "13:1", "13:2"], ["5:0", "5:2", "5:1"], 
                         ["5:0", "3:2", "5:2"], ["3:2", "4:1", "3:2", "4:0"], ["3:2", "0:0", "3:2"]]
          valid_runs = [ ["5:3", "6:3", "7:3"], ["5:1", "4:1", "3:1"], ["1:3", "2:3", "3:3", "4:3"],
                         ["1:3", "2:3", "3:3", "4:3", "5:3", "6:3", "7:3", "8:3"],
                         ["3:2", "6:3", "7:3"], ["5:3", "3:2", "7:3"], ["5:3", "6:3", "3:2"],
                         ["7:3", "6:3", "3:2"], ["7:3", "3:2", "5:3"], ["3:2", "6:3", "5:3"],
                         ["5:3", "3:2", "3:2", "8:3"], ["3:2", "6:3", "3:2", "8:3"], ["3:2", "4:1", "5:1", "3:2"],
                         ["8:3", "3:2", "3:2", "5:3"], ["8:3", "3:2", "6:3", "3:2"], ["3:2", "5:1", "4:1", "3:2"],
                         ["0:0", "4:2", "5:2"], ["2:2", "0:1", "4:2"], ["1:2", "2:2", "0:1"],
                         ["5:2", "4:2", "0:0"], ["3:2", "0:1", "2:2"], ["0:1", "2:2", "1:2"],
                         ["0:0", "3:2", "5:2"], ["5:2", "3:2", "0:1"],
                         ["12:0", "13:0", "1:0"], ["3:2", "13:0", "1:0"], ["12:0", "3:2", "1:0"], ["12:0", "13:0", "3:2"],
                         ["3:2", "3:2", "1:0"], ["11:2", "12:2", "13:2"], ["13:2", "12:2", "11:2"]]
          #groups
          @invalid_groups = []
          invalid_groups.each do |group|
            g = Okey::TileParser.parse_group(group)
            raise "nil group " + group.to_s if g.nil?
            @invalid_groups << g
          end
          
          @valid_sets = []
          valid_sets.each do |group|
            g = Okey::TileParser.parse_group(group)
            raise "nil group " + group.to_s if g.nil?
            @valid_sets << g
          end
          
          @valid_runs = []
          valid_runs.each do |group|
            g = Okey::TileParser.parse_group(group)
            raise "nil group " + group.to_s if g.nil?
            @valid_runs << g
          end
          
        end
        
        before(:each) do
          @tile_bag = Okey::TileBag.new
          @tile_factory = Okey::TileFactory.instance
          @tile_bag.instance_variable_set(:@indicator, @tile_factory.get(2,2))
        end
        
        describe "sets" do
          
          it "should return false on invalid sets" do
            @invalid_groups.each do |group|
              @tile_bag.send(:check_set, group).should == false
            end
          end
          
          it "should return true on valid sets" do
            @valid_sets.each do |group|
              @tile_bag.send(:check_set, group).should == true
            end
          end
          
        end
        
        describe "runs" do
          
          it "should return false on invalid runs" do
            @invalid_groups.each do |group|
              @tile_bag.send(:check_run, group).should == false
            end
          end
          
          it "should return true on valid runs" do
            @valid_runs.each do |group|
              @tile_bag.send(:check_run, group).should == true
            end
          end
          
        end
      end
      
      describe "general check" do
        
        # indicator = 13:3
        before(:all) do
          @thrown_tile = Okey::TileFactory.instance.get(5,1)
          valid_hands = [
            [["3:1", "2:1", "1:1"], ["4:0", "4:3", "4:1"], ["7:2", "8:2", "9:2", "1:3", "11:2"], ["0:1", "1:0", "1:2"]],
            [["13:1", "13:2", "13:0", "13:3"], ["12:0", "13:0", "1:0"], ["0:0", "1:3", "1:3"], ["0:1", "2:3", "1:3", "4:3"]],
            [["3:1", "3:1"], ["7:0", "7:0"], ["13:2", "13:2"], ["8:1", "8:1"], ["1:0", "1:0"], ["1:3", "1:3"], ["2:2", "2:2"]],
            [["0:1", "0:0"], ["7:0", "1:3"], ["1:3", "13:2"], ["13:3", "13:3"], ["5:0", "5:0"], ["5:1", "5:1"], ["3:2", "3:2"]]]
          invalid_hands = [
            [["3:1", "2:1", "1:1"], ["4:0", "4:3", "4:1"], ["7:2", "8:2", "9:2", "1:3", "11:2"], ["0:1", "1:2"]],
            [["3:1", "3:1"], ["4:0", "4:3", "4:1"], ["7:2", "8:2", "9:2", "1:3", "11:2"], ["3:1", "2:1", "1:1"]],
            [["13:1", "13:2", "13:0", "13:3"], ["12:0", "13:0", "1:0", "2:0", "3:0"], ["0:0", "1:3", "1:3"]],
            [["0:0", "1:3", "1:3", "3:3"], ["3:1", "2:1", "1:1"], ["4:0", "4:3", "4:1"]],
            [["3:1", "3:1"], ["7:0", "7:0"], ["13:2", "13:2"], ["8:1", "8:1"], ["1:0", "1:0"], ["1:3", "1:3"], ["2:2"]],
            [["3:1", "3:1"], ["7:0", "7:0"], ["13:2", "13:2"], ["8:1", "8:1"], ["1:0", "1:0"], ["1:3", "1:3"], ["2:2", "2:2", "2:2"]],
            [["3:1", "4:1"], ["7:0", "1:3"], ["1:3", "13:2"], ["13:3", "13:3"], ["5:0", "5:0"], ["5:1", "5:1"], ["3:2", "3:2"]]]
            
          @valid_hands = []
          valid_hands.each do |hand|
            h = []
            hand.each do |group|
              g = Okey::TileParser.parse_group(group)
              raise "nil group " + group.to_s if g.nil?
              h << g
            end
            @valid_hands << h
          end
          
          @invalid_hands = []
          invalid_hands.each do |hand|
            h = []
            hand.each do |group|
              g = Okey::TileParser.parse_group(group)
              raise "nil group " + group.to_s if g.nil?
              h << g
            end
            @invalid_hands << h
          end
          
        end
        
        before(:each) do
          @tile_bag = Okey::TileBag.new
          @tile_factory = Okey::TileFactory.instance
          @tile_bag.instance_variable_set(:@indicator, @tile_factory.get(13,3))
        end
        
        it "should return true on valid hand" do
          @valid_hands.each do |hand|
            @tile_bag.send(:check_to_finish, hand.flatten.push(@thrown_tile), hand, @thrown_tile).should == true
          end
        end
        
        it "should return false on invalid hand" do
          @invalid_hands.each do |hand|
            @tile_bag.send(:check_to_finish, hand.flatten.push(@thrown_tile), hand, @thrown_tile).should == false
          end
        end
        
      end
      
    end
    
    
    
  end

  describe Okey::TileFactory do
    
    it "should return same object on get" do
      tile_factory = Okey::TileFactory.instance
      tile = tile_factory.get(1, Okey::Tile::BLACK)
      tile_factory.get(1, Okey::Tile::BLACK).should equal(tile)
    end
    
  end
  
  describe Okey::TileParser do
    
    it "should return appropriate tiles" do
      tile_bag = Okey::TileBag.new
      tile_bag.instance_variable_get(:@bag).each do |tile|
        t_parsed = Okey::TileParser.parse(tile.to_s)
        tile.should equal(t_parsed)
      end
    end
    
    it "should return nil on unexpected strings" do
      ary = ['', '-1:0', '14:0', '0:2', '0:3', '1:-1', '1:4', '1:3:1', ':', '::', '12', '123', ':3:2', ' ']
      ary.each do |string|
        t_parsed = Okey::TileParser.parse(string)
        t_parsed.should == nil
      end
    end
    
  end

  describe Okey::Tile do

  # find better way to check raised errors
    it "should raise error on invalid color" do
      # invalid color test > 3
      error = nil
      begin; Okey::Tile.new(3, 4); rescue Exception => e; error = e; end
      error.should_not == nil
      # invalid color test < 0
      error = nil
      begin; Okey::Tile.new(3, -1); rescue Exception => e; error = e; end
      error.should_not == nil
    end

    it "should raise error on invalid value" do
    # invalid value test > 13
      error = nil
      begin; Okey::Tile.new(14, Okey::Tile::BLACK); rescue Exception => e; error = e; end
      error.should_not == nil
      # invalid value test < 0
      error = nil
      begin; Okey::Tile.new(-1, Okey::Tile::BLACK); rescue Exception => e; error = e; end
      error.should_not == nil
    end

    it "should raise error on invalid joker color" do
    # invalid joker color test = BLUE
      error = nil
      begin; Okey::Tile.new(0, Okey::Tile::BLUE); rescue Exception => e; error = e; end
      error.should_not == nil
      # invalid joker color test = RED
      error = nil
      begin; Okey::Tile.new(0, Okey::Tile::RED); rescue Exception => e; error = e; end
      error.should_not == nil
    end

  end

end