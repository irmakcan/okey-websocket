module Okey
  class Room
    attr_reader :name
    def initialize(lounge, room_name)
      @table = Table.new
      @lounge = lounge
      @name = room_name
      @room_channel = EventMachine::Channel.new
    end

    def join_room(user)
      user.sid = @room_channel.subscribe { |msg|
        user.websocket.send(msg)
      }
      user.websocket.onmessage { |msg|
        begin
          json = JSON.parse(msg)
          handle_request(user, json)
        rescue JSON::ParserError
          result = { :status => :error, :payload => { :message => "messaging error" }}.to_json
          user.websocket.send(result)
        rescue ArgumentError => message
          result = { :status => :error, :payload => { :message => message }}.to_json
          user.websocket.send(result)
        end
      }
      #user.websocket.onclose {}
      user.position = @table.add_user(user)
      # publish user with location
      @room_channel.push(ChairStateMessage.getJSON(@table.chairs))
      if @table.full? && @game.nil?
        @game = Game.new(@room_channel, @table)
      end
    end

    def leave_room(user)
      @table.remove(user.position)
      @lounge.destroy_room(self) if @table.empty?
      @room_channel.unsubscribe(user.sid)
      # publish leaved
      @room_channel.push(ChairStateMessage.getJSON(@table.chairs))
      @lounge.join_lounge(user)
    end

    def count
      @table.count
    end

    def full?
      @table.full?
    end

    private

    def handle_request(user, json)
      case json['action']
      when 'throw_tile'
        tile = TileParser.parse(json['tile'])
        finish = json['finish']
        if tile.nil? || finish.nil?
          raise ArgumentError, 'invalid tile'
        end
        @game.throw_tile(user, tile, finish) 
      when 'leave_room'
        # leave_room(user) TODO
        # @game replace AI
      else # Send err
        raise ArgumentError, 'messaging error'
      end
    end

  end
end