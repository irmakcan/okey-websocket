module Okey
  class Player
    attr_accessor :username, :position
  end
  
  class OkeyBot < Player
    include EM::Deferrable
    
    def initialize(hand)
      @hand = hand
    end
    
    # def self.play_draw(left_tile, hand)
      # self.succeed(:center) # draw center tile
    # end
#     
    # def play_draw(left_tile)
      # OkeyBot.play_draw(left_tile, @hand)
    # end
#     
    # def self.play_throw(retreived_tile, hand)
      # self.succeed(retreived_tile) # throw retreived tile
    # end
#     
    # def play_throw(retreived_tile)
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



    def self.authenticate_with_salt(username, cookie_salt)
      # user = find_by_username username # DB search
      # (user && user.salt == cookie_salt) ? user : nil # TODO change
    end
    
    private
      def encrypt_password
        
      end
  end
end