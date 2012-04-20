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
    
    def initialize(hand)
      @hand = hand
    end
    
    def bot?
      true
    end
    
    def send(hash)
      if hash[:turn] == @position
        if hash[:status] == :throw_tile
          tile = hash[:tile]
          # Let's draw center tile
          # TODO should call call back .......
          @draw_callback.call(true) # center = true
        elsif hash[:status] == :draw_tile
          tile = hash[:tile]
          # Let's throw what we have drawn
          @throw_callback.call(tile)
        end
      end
    end
    
    def onmessage(&blk)

    end
    
    def onclose(&blk)
  
    end
    
    def draw_callback(&block)
      @draw_callback = block
      #OkeyBot.play_draw(left_tile, @hand)
    end
    
    def throw_callback(&block)
      @throw_callback = block
      #OkeyBot.play_throw(retreived_tile, @hand)
    end
    
    def finish_callback(&block)
      @finish_callback = block
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