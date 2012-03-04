require 'singleton'

module Okey
  class TileBag
    NUM_OF_TILES = 106
    RIGHT_CORNER = { :south => :se, :east => :ne, :north => :nw, :west => :sw }
    LEFT_CORNER = { :south => :sw, :east => :se, :north => :ne, :west => :nw }
    
    attr_reader :hands
    
    def initialize
      @bag = []
      @corner_tiles = { :se => [], :ne => [], :nw => [], :sw => [] }
      tile_factory = TileFactory.instance
      2.times do
        Tile::COLORS.each do |color|
          Tile::RANGE.each do |value|
            @bag << tile_factory.get(value, color)
          end
        end
      end
      @bag << tile_factory.get(0, Tile::BLACK)  # Black joker
      @bag << tile_factory.get(0, Tile::ORANGE) # Orange joker
      @bag.shuffle!
    end
    
    def distibute_tiles(chairs, starting_position)
      chairs.each_key do |position|
        @hands.merge!({ position => @bag.shift((position == starting_position ? 15 : 14)) })
      end
    end
    
    def draw_middle_tile(position)
      if @hands[position].length != 14
        return nil
      end
      tile = @bag.shift
      @hands[position] << tile
      tile
    end
    
    def draw_left_tile(position, tile)
      if @hands[position].length != 14
        return nil
      end
      if @corner_tiles[LEFT_CORNER[position]].last == tile
        t = @corner_tiles[LEFT_CORNER[position]].pop
        @hands[position] << t
        return t
      end
    end
    
    def throw_tile(position, tile)
      if @hands[position].length != 15
        return nil
      end
      if @hands[position].include?(tile)
        t = @hands[position].delete(tile)
        @corner_tiles[RIGHT_CORNER[position]].push(t)
        return t
      end
    end
    
    # check for the end
    # def throw_tile_finish(position, tile)
#       
    # end
    
  end
  
  # flyweight pattern
  class TileFactory
    include Singleton
    
    def initialize
      @tiles = {}
    end
    
    def get(value, color)
      stamp = Tile.stamp(value, color)
      return @tiles[stamp] if @tiles.include?(stamp)
      @tiles[stamp] = Tile.new(value, color)
    end
    
  end
  
  # Immutable
  class Tile
    BLACK = 0
    ORANGE = 1
    BLUE = 2
    RED = 3
    
    COLORS = [BLACK, BLUE, RED, ORANGE]
    
    RANGE = 1..13
    
    attr_reader :value, :color
    
    def initialize(value, color)
      if (value == 0) && (color == BLACK || color == ORANGE) # Jokers
        @value = value
        @color = color
      else
        if (!COLORS.include?(color) || !RANGE.cover?(value))
          raise "Argument Error"
        end
        @value = value
        @color = color
      end
    end
    
    def self.stamp(value, color)
      "#{value}:#{color}"
    end
    
    def to_s
      Tile.stamp(@value, @color)
    end
    
  end
  
end