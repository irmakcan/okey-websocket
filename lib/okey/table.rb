
module Okey
  class Table
    attr_reader :chairs, :state
    def initialize
      @chairs = {}
      @game = nil
      @state = :waiting
    end
    
    def initialize_game
      if @game.nil?
        @game = Game.new(self)
        @state = :started
      end
    end
    
    # returns the added position or nil
    def add_user(user)
      index = 0
      position = nil
      while index < 4
        key = Chair::POSITIONS[index]
        if !@chairs.has_key?(key)
          position = key
          @chairs.merge!({ key => user})
          break
        end
        index += 1
      end
      user.position = position
      position        
    end
    
    def init_bot(bot, position)
      @game.init_bot(bot, position)
    end
    
    def get_user(position)
      @chairs[position]
    end
    
    def remove(position)
      @chairs.delete(position)
    end
    
    def user_count
      count = 0
      @chairs.each_value do |player|
        count += 1 unless player.bot?
      end
      count
    end
    
    def full?
      @chairs.length >= 4
    end
    
    def has_bot?
      user_count() < 4
    end
    
    def empty?
      @chairs.length <= 0
    end
    
    def all_ready?
      ready = true
      @chairs.each_value do |player|
        ready &&= player.ready?
      end
      ready
    end
     
    
    def game_started?
      @state == :started
    end
    
    def turn
      @game.turn if game_started?
    end
    
    def tile_bag
      @game.tile_bag if game_started?
    end
    
    def throw_tile(user, tile)
      @state = :finished if @game.middle_tile_count <= 0
      @game.throw_tile(user, tile)
    end
    
    def throw_to_finish(user, hand, tile)
      success = @game.throw_to_finish(user, hand, tile)
      if success
        @state = :finished
      end
      success
    end
    
    def draw_tile(user, center)
      @game.draw_tile(user, center)
    end
    
    def middle_tile_count
      @game.middle_tile_count
    end
    
    
    
  end
end