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