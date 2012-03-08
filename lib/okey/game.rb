module Okey
  class Game
    def initialize(channel, table)
      @channel = channel
      @table = table
      @turn = :south
      @tile_bag = TileBag.new
      @tile_bag.distibute_tiles(@table.chairs, @turn)

      @table.chairs.each do |position, user|
        user.websocket.send(GameStartingMessage.getJSON(user.position == @turn,
                                                        @tile_bag.center_tile_left,
                                                        @tile_bag.hands[user.position],
                                                        @tile_bag.indicator))
      end
    end

    def throw_tile(user, tile)
      return GameMessage.getJSON(:error, nil, 'not your turn') if @turn != user.position

      success = @tile_bag.throw_tile(user.position, tile)

      if !success
        return GameMessage.getJSON(:error, nil, 'invalid move')
      else
        @turn = Chair.next(user.position)
        @channel.push({ :action => :throw_tile,
                        :turn => @turn,
                        :tile => tile.to_s,
                        :corner => TileBag::RIGHT_CORNER[user.position] }.to_json)
      end
      nil
    end

    def throw_to_finish(user, tile)
      # TODO
    end

    def draw_tile(user, center)
      return GameMessage.getJSON(:error, nil, 'not your turn') if @turn != user.position
      if center
        success = @tile_bag.draw_middle_tile(user.position)
      else
        success = @tile_bag.draw_left_tile(user.position)
      end

      if !success
        return GameMessage.getJSON(:error, nil, 'invalid move')
      else
        @channel.push({ :action =>       :draw_tile,
                        :turn =>         user.position,
                        :center =>       center,
                        :center_count => @tile_bag.center_tile_left,
                        :corner =>       TileBag::LEFT_CORNER[user.position] }.to_json)
      end
      nil
    end

  end
end