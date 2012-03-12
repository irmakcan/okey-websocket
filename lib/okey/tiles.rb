require 'singleton'

module Okey
  class TileBag
    NUM_OF_TILES = 106
    RIGHT_CORNER = { :south => :se, :east => :ne, :north => :nw, :west => :sw }
    LEFT_CORNER  = { :south => :sw, :east => :se, :north => :ne, :west => :nw }
    
    attr_reader :hands, :indicator
    
    def initialize
      @bag = []
      @hands = {}
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
      tile = @bag.shift
      while tile.value == 0
        @bag.push(tile)
        tile = @bag.shift
      end
      @indicator = tile
    end
    
    def draw_middle_tile(position)
      return nil if @hands[position].length != 14 || @bag.empty?
      tile = @bag.shift
      @hands[position] << tile
      tile
    end
    
    def draw_left_tile(position)
      return nil if @hands[position].length != 14 || @corner_tiles[LEFT_CORNER[position]].empty?
      t = @corner_tiles[LEFT_CORNER[position]].pop
      @hands[position] << t
      t
    end
    
    def throw_tile(position, tile)
      return false if @hands[position].length != 15 || !@hands[position].include?(tile)
      t = @hands[position].delete(tile)
      @corner_tiles[RIGHT_CORNER[position]].push(t)
      true
    end
    
    # hand => array of grouped tiles array
    def throw_tile_center(position, hand, tile)
      return false if @hands[position].length != 15 || !@hands[position].include?(tile)
      return check_to_finish(@hands[position], hand, tile)
    end
    
    def center_tile_left
      @bag.length
    end
    
    # check for the end
    # def throw_tile_finish(position, tile)
#       
    # end
    private
      def check_to_finish(real_hand, sent_hand, thrown_tile)
        rh = real_hand.sort { |a,b| comp = (a.value <=> b.value); comp.zero? ? a.color <=> b.color : comp }
        sh = sent_hand.flatten.push(thrown_tile).sort { |a,b| comp = (a.value <=> b.value); comp.zero? ? a.color <=> b.color : comp }
        return false if rh != sh # check for equality
        return (sent_hand[0].length == 2 ? 
                  check_double(sent_hand) : 
                  check_normal(sent_hand) )
      end
      
      def check_double(sent_hand)
        joker = TileFactory.instance.get((@indicator.value % 13) + 1, @indicator.color)
        sent_hand.each do |group|
          return false if group.length != 2
          if group[0] != group[1]
            return true if (group[0].fake_joker? && group[0].fake_joker?)
            return false if (group[0] != joker) || (group[1] != joker)
          end
        end
        true
      end
      
      def check_normal(sent_hand)
        sent_hand.each do |group|
          return false if group.length < 3
          if check_set(group) || check_run(group)
            next
          else
            return false
          end 
        end
        true
      end
      
      def check_set(group)
        joker = TileFactory.instance.get((@indicator.value % 13) + 1, @indicator.color)
        
        value = 0
        colors = []
        group.each do |tile|
          next if tile == joker
          t = (tile.fake_joker? ? TileFactory.instance.get(joker.value, joker.color) : tile )
          if value > 0
            return false if value != t.value || colors.include?(t.color)
          else
            value = t.value
            colors << t.color
          end 
        end
        true
      end
      
      def check_run(group)
        joker = TileFactory.instance.get((@indicator.value % 13) + 1, @indicator.color)
        
        group.map! do |tile|
          if tile == joker
            TileFactory.instance.get(0, 0)
          else
            (tile.fake_joker? ? TileFactory.instance.get(joker.value, joker.color) : tile )
          end
        end
        # now on, fake joker is a real joker (Okey)
        
        color = nil
        raw_values = []
        group.each do |tile| 
          if tile.fake_joker?
            raw_values << -1
          else
            if color.nil?
              color = tile.color
            elsif tile.color != color
              return false
            end
            raw_values << tile.value
          end
        end
        
        #raw_values.each
        success = check_incr(raw_values)
        success = check_decr(raw_values) unless success
        success
      end
      # check increamental runs
      def check_incr(values)
        values = values.dup
        
        #if values.include?(13) && values.length <= 13
        if values.include?(1) && values.index(1) == values.length - 1
          values.map! { |t| (t == 1 ? 14 : t) }
          # return false if any tile comes after the 1 (14)
          return false if values.index(14) != values.length - 1
        elsif values.include?(1)
          return false if values[0] != 1
        elsif values.include?(2)
          return false unless values.index(2) < 2
        end
        
        last_value = nil
        index = 0
        while index < values.length
          t = values[index]
          
          if last_value.nil?
            if t != -1
              last_value = t
            end
          else
            if t == -1
              last_value += 1
            else
              return false if last_value + 1 != t
              last_value = t
            end
          end
          
          index += 1
        end
        true
      end
      
      # check decremental runs
      def check_decr(values)
        values = values.dup
        #if values.include?(13) && values.length <= 13
        if values.include?(1) && values.index(1) == 0
          
          values.map! { |t| (t == 1 ? 14 : t) }
          # return false if any tile comes after the 1 (14)
          return false if values.index(14) != 0
        elsif values.include?(1)
          
          return false if values[values.length-1] != 1
        elsif values.include?(2)
          return false if values.index(2) < values.length - 2
        end
        
        last_value = nil
        index = 0
        while index < values.length
          t = values[index]
          
          if last_value.nil?
            if t != -1
              last_value = t
            end
          else
            if t == -1
              last_value -= 1
            else
              return false if last_value - 1 != t
              last_value = t
            end
          end
          
          index += 1
        end
        true
      end
  end
  
  class TileParser
    def self.parse(string)
      return nil unless string =~ /^\d+:\d$/
      t = string.split(':')
      t.collect! { |str| str.to_i }
      tile_factory = TileFactory.instance
      if Tile::RANGE.include?(t[0])
        return tile_factory.get(t[0], t[1]) if Tile::COLORS.include?(t[1])
      elsif t[0] == 0 # Joker
        return tile_factory.get(t[0], t[1]) if t[1] == Tile::BLACK || t[1] == Tile::ORANGE
      end
      nil          
    end
    
    def self.parse_group(group)
      parsed = []
      group.each do |tile|
        t = parse(tile)
        return nil if t.nil?
        parsed << t
      end
      parsed.empty? ? nil : parsed
    end
    
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
    
    def fake_joker?
      @value == 0
    end
    
    def to_s
      Tile.stamp(@value, @color)
    end
    
  end
  
end