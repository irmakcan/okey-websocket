require 'em-hiredis'

module Okey
  class UserController
  
    def initialize(opts=nil)
      @env = opts[:env] if opts
    end
  
    def subscribe(user)
      user.onmessage { |msg|

        handle_request(user, msg) do |error|
          if error
            user.send error
          else
          # Everything went well (authenticated)
            @lounge = Lounge.new(self) unless @lounge
            @lounge.join_lounge(user)
          end
        end
      }
      user.onclose {
        user = nil # not truly necessary
      }
    end

    private

    def handle_request(user, msg, &blck)
      json = nil
      begin
        json = JSON.parse(msg)
      rescue JSON::ParserError
        json = nil
      end

      if json.nil? || json["action"] != "authenticate"
        blck.call AuthenticationMessage.getJSON(:error, nil, "Messaging error")
        return
      elsif json["version"] != Server.version
        blck.call AuthenticationMessage.getJSON(:error, nil, "Incompatible version")
        return
      end 

      authenticate(json["username"], json["access_token"]) do |authenticated, points|
        unless authenticated
          blck.call AuthenticationMessage.getJSON(:error, nil, "Authentication error")
        else 
          user.username = json["username"]
          user.points = points
          user.authenticated = true
          blck.call nil
        end
      end
    end

    def authenticate(username, access_token, &blck)
      if username.nil? || username.empty? || username =~ /\s/ || access_token.nil?
        blck.call false
        return
      end
      
      if @env == :production
        key = "auth:#{username.to_s}"
        $redis.hgetall(key).callback { |value_arr|
          hash = Hash[*value_arr]
          if hash['access_token'] == access_token && hash['points'] != nil
            # Delete key
            $redis.del(key)
            blck.call true, hash['points'].to_i
          else
            blck.call false, nil
          end
        }
      else
        blck.call true, 0
      end
      
    end

  end
end