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
        error = handle_request(user, msg)
        if error
          user.websocket.send error
        end
      }
      #user.websocket.onclose {}
      user.position = @table.add_user(user)
      # Send his location and table infos
      user.websocket.send(JoinResponseMessage.getJSON(user, @table.chairs))
      # publish user with location
      channel_msg = JoinChannelMessage.getJSON(user)
      @table.chairs.each do |position, usr|
        usr.websocket.send(channel_msg) if user.position != position
      end
      # start game
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

    def handle_request(user, msg)
      json = nil
      begin
        json = JSON.parse(msg)
      rescue JSON::ParserError
        json = nil
      end
      
      return RoomMessage.getJSON(:error, nil, "messaging error") if json.nil?
      
      error = nil
      case json['action']
      when 'throw_tile'
        tile = TileParser.parse(json['tile'])
        return RoomMessage.getJSON(:error, nil, 'messaging error') if tile.nil?
        error = @game.throw_tile(user, tile) # returns logical error if occurs
      when 'draw_tile'
        center = json['center']
        return RoomMessage.getJSON(:error, nil, 'messaging error') if center.nil?
        error = @game.draw_tile(user, center)
      when 'throw_to_finish'
        tile = TileParser.parse(json['tile'])
        raw_hand = json['hand']
        return RoomMessage.getJSON(:error, nil, 'messaging error') if tile.nil?
        error = @game.throw_to_finish(user, tile)
      when 'leave_room'
        # leave_room(user) TODO
        # @game replace AI
      else # Send err
        error = RoomMessage.getJSON(:error, nil, "messaging error")
      end
      error
    end

  end
end