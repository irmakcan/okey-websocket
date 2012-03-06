module Okey
  class UserController

    def subscribe(user)
      # May publish connection established
      # user.websocket.send json(connection established)
      user.websocket.onmessage { |msg|

        error = handle_request(user, msg)
        if error
          user.websocket.send error
        else
        # Everything went well (authenticated)
          @lounge = Lounge.new(self) unless @lounge
          @lounge.join_lounge(user)
        end
      }
    end

    private

    def handle_request(user, msg)
      json = nil
      begin
        json = JSON.parse(msg)
      rescue JSON::ParserError
        json = nil
      end

      return AuthenticationMessage.getJSON(:error, nil, "messaging error") if json.nil? || json["action"] != "authenticate"
      return AuthenticationMessage.getJSON(:error, nil, "incompatible version") if json["payload"]["version"] != Server.version

      authenticated = authenticate(json["payload"]["username"], json["payload"]["salt"])
      return AuthenticationMessage.getJSON(:error, nil, "authentication error") unless authenticated

      user.username = json["payload"]["username"]
      user.authenticated = true
      nil
    end

    def authenticate(username, cookie_salt)
      if username.nil? || username.empty? || username =~ /\s/
      return false
      end
      # do authenticate

      true
    end

  end
end