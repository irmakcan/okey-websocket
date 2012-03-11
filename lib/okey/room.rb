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
      if @game.nil?
        @room_channel.push(LeaveChannelMessage.getJSON(user.position))
      else # add AI TODO
        @room_channel.push(LeaveReplacedChannelMessage.getJSON(user.position, "AI")) # Will be real AI TODO
      end
      
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
      
      error_msg = nil
      case json['action']
      when 'throw_tile'
        tile = TileParser.parse(json['tile'])
        return RoomMessage.getJSON(:error, nil, 'messaging error') if tile.nil? || @game.nil?
        error_msg = @game.throw_tile(user, tile) # returns logical error if occurs
      when 'draw_tile'
        center = json['center']
        return RoomMessage.getJSON(:error, nil, 'messaging error') if center.nil? || @game.nil?
        error_msg = @game.draw_tile(user, !!center)
      when 'throw_to_finish'
        tile = TileParser.parse(json['tile'])
        raw_hand = json['hand']
        
        hand = nil
        if raw_hand.is_a?(Array)
          hand = []
          raw_hand.each do |group|
            if !group.is_a?(Array)
              hand = nil
              break
            end
            g = TileParser.parse_group(group)
            if g.nil? 
              hand = nil
              break
            end 
            hand << g
          end
        end
        
        return RoomMessage.getJSON(:error, nil, 'messaging error') if tile.nil? || @game.nil? || hand.nil? || hand.empty?
        error_msg = @game.throw_to_finish(user, hand, tile)
        if error_msg.nil? # Game ends
          @table.chairs.each_value do |user|
            @game = nil
            leave_room(user)
          end
        end
        
      when 'leave_room'
        leave_room(user)
      else # Send err
        error_msg = RoomMessage.getJSON(:error, nil, "messaging error")
      end
      error_msg
    end

  end
end