module Okey
  class User
    attr_accessor :username, :subscribed_channel_id
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