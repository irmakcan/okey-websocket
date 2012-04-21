module Okey
  class Player
    attr_accessor :username, :position
    
    def bot?
      false
    end
    
  end
  
  # class OkeyAI
    # include EM::Deferrable
#     
    # def initialize()
#       
    # end
#     
  # end
  
  class OkeyBot < Player
    attr_accessor :sid
    
    def initialize(hand, indicator, left_tile)
      @indicator = indicator
      @left_tile = left_tile
      @hand = hand.dup
      
      @ready = true
    end
    
    def bot?
      true
    end
    
    def force_play
      if @hand.length == 14
        play_draw(@left_tile)
      else
        play_throw
      end
    end
    
    def play_draw(left_tile)
      # if left_tile.nil? must draw from center
      # For now let's always draw center tile
      @draw_callback.call(true) # center = true
    end
    
    def play_throw
    # for now let's always throw the last tile in the hand
      last_index = @hand.length - 1
      tile = @hand.delete_at(last_index)
      @throw_callback.call(tile)
      
    end
    
    def send(hash)
      if hash[:turn] == @position
        if hash[:status] == :throw_tile
          tile = hash[:tile]
          play_draw(tile)
        elsif hash[:status] == :draw_tile
          tile = hash[:tile]
          @hand.push(tile)
          play_throw
        end
      end
    end
    
    def onmessage(&blk)

    end
    
    def onclose(&blk)
  
    end
    
    def draw_callback(&block)
      @draw_callback = block
    end
    
    def throw_callback(&block)
      @throw_callback = block
    end
    
    def finish_callback(&block)
      @finish_callback = block
    end
    
    def ready?
      @ready
    end
    
    def ready=(state)
      @ready = state
    end
    
  end
  
  class User < Player
    attr_accessor :sid
    attr_reader :websocket
    
    def initialize(websocket)
      @websocket = websocket
      @ready = false
    end

    def ready?
      @ready
    end
    
    def ready=(state)
      @ready = state
    end

    def authenticated?
      @authenticated
    end
    def authenticated=(auth)
      @authenticated = auth
    end

    def send(hash)
      @websocket.send(hash.to_json)
    end
    
    def onmessage(&blk)
      @websocket.onmessage(&blk)
    end
    
    def onclose(&blk)
      @websocket.onclose(&blk)
    end
    
    def state
      @websocket.state
    end

    def self.authenticate_with_salt(username, cookie_salt)
      # user = find_by_username username # DB search
      # (user && user.salt == cookie_salt) ? user : nil # TODO change
    end
    
    private
      def encrypt_password
        
      end
  end
end