module Okey
  class UserController
    def initialize(version)
      @version = version

    end

    # FIXME Messed up logic TODO
    def subscribe(user)
      # May publish connection established
      # user.websocket.send json(connection established)
      user.websocket.onmessage { |msg|
      # result = nil
        begin
          json = JSON.parse(msg)
          result = validate_message(json)
        rescue JSON::ParserError
          result = { :status => :error, :payload => { :message => "messaging error" }}.to_json
        end

        if result.nil?
          # Everything went well (authenticated)
          user.username = json["payload"]["username"]
          user.authenticated = true

          @lounge = Lounge.new(self) unless @lounge
        @lounge.join_lounge(user)
        else
        user.websocket.send result
        end

      }
    end

    private

    def validate_message(json)
      message = nil

      if json["action"] == "authenticate"
        if json["payload"]["version"] != @version
          # send version error TODO
          message = { :status => :error, :payload => { :message => "incompatible version" }}.to_json
        else
          if !authenticate(json["payload"]["username"], json["payload"]["salt"])
            # send authentication error TODO
            message = { :status => :error, :payload => { :message => "authentication error" }}.to_json
          end
        end
      else
        message = { :status => :error, :payload => { :message => "messaging error" }}.to_json
      end
      message
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