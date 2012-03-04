module Okey
  class Game
    def initialize(channel, table)
      @channel = channel
      @table = table
      @tile_bag = TileBag.new
      @tile_bag.distibute_tiles(@table.chairs, :south) # TODO change starting position
    end
  
    def start_game

    end

    

  end
end