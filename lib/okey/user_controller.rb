module Okey
  class UserController
    
    def initialize

    end

    def subscribe(user)
      # May publish connection established
      # user.websocket.send json(connection established)
      user.websocket.onmessage { |msg|
        json = JSON.parse(msg)

        if json
          if json["version"] != '0.0.0' # @@version TODO
            # send version error TODO
          else
            if !authenticate(user, json["username"], json["cookie_salt"])
              # send authentication error TODO
            else
              puts "#{user.username} authenticated"
              # add to okey lounge
            end
          end
        end
      }
    end


    private
      def authenticate(user, username, cookie_salt)
        # do authenticate
        
        
        result = true
        user.username = username
        user.authenticated = result
        result
      end

  end
end