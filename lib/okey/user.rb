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
      @websocket.send(hash.to_json)
    end
    
    def onmessage(&blk)

    end
    
    def onclose(&blk)
  
    end
    
    # def play_draw(left_tile, &block)
      # @draw_callback = block
      # OkeyBot.play_draw(left_tile, @hand)
    # end
#     
    # def play_throw(retreived_tile, &block)
      # OkeyBot.play_throw(retreived_tile, @hand)
    # end
    
  end
  
  class User < Player
    attr_accessor :sid
    attr_reader :websocket
    
    def initialize(websocket)
      @websocket = websocket
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