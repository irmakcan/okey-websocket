module Okey
  class Game
    attr_reader :turn, :tile_bag
    def initialize(table)
      @table = table
      @turn = :south
      @tile_bag = TileBag.new
      @tile_bag.distibute_tiles(@table.chairs, @turn)

      @table.chairs.each do |position, user|
        user.send(GameStartingMessage.getJSON(@turn,
                                              @tile_bag.center_tile_left,
                                              @tile_bag.hands[position],
                                              @tile_bag.indicator))
        if @turn == user.position
          user.start_timer(:throw, @tile_bag.hands[user.position])
        end
      end
    end

    # True | False
    def throw_tile(user, tile)
      return false if @turn != user.position

      success = @tile_bag.throw_tile(user.position, tile)

      if success
        @turn = Chair.next(user.position)
        user.cancel_timer
        @table.chairs[@turn].start_timer(:draw) if @tile_bag.center_tile_left > 0 # Next player should draw
      end
          
      success
    end

    # True | False
    def throw_to_finish(user, hand, tile)
      return false if @turn != user.position
      @tile_bag.throw_tile_center(user.position, hand, tile)
    end

    # Tile | Nil
    def draw_tile(user, center)
      return nil if @turn != user.position
      tile = nil
      if center
        tile = @tile_bag.draw_middle_tile(user.position)
      else
        tile = @tile_bag.draw_left_tile(user.position)
      end
      if !tile.nil?
        user.cancel_timer
        user.start_timer(:throw, @tile_bag.hands[user.position])
      end
      tile
    end
    
    def middle_tile_count
      @tile_bag.center_tile_left
    end
    
    # TODO test
    # def add_bot(okey_bot)
      # @bots.merge!({ okey_bot.position => okey_bot })
    # end
    def init_bot(bot, position)
      bot.init_bot(@tile_bag.hands[position], @tile_bag.indicator, @tile_bag.corner_tiles[Okey::TileBag::LEFT_CORNER[position]].last)
    end

  end
end