module Okey
  class Game
    def initialize(channel, table)
      @channel = channel
      @table = table
      @turn = :south
      @tile_bag = TileBag.new
      @tile_bag.distibute_tiles(@table.chairs, @turn) # TODO change starting position
      
      @table.chairs.each { |position, user|
        user.websocket.send(GameStartingMessage.getJSON(user.position == @turn, @tile_bag.center_tile_left, user.position))
      }
    end
    
    def throw_tile(user, tile, finish)
      raise 'not your turn' if @turn != user.position
      if check_move(user, tile, finish)
        if finish
          
        else
          @tile_bag.throw_tile(user.position, tile)
        end
        
      end
      
    end
    
    def check_move(user, tile, finish)
      true
    end
    # def reset_game

  end
end