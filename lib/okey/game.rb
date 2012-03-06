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
      return GameMessage.getJSON(:error, nil, 'not your turn') if @turn != user.position
      if finish
        result = @tile_bag.throw_tile_center(user.position, tile)
      else
        result = @tile_bag.throw_tile(user.position, tile)
      end
      
      return GameMessage.getJSON(:error, nil, 'invalid move') unless result 
      nil
    end
    
  end
end