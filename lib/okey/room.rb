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
      user.sid = @room_channel.subscribe { |hash|
        user.send(hash)
      }
      user.onmessage { |msg|
        error = handle_request(user, msg)
        if error
          user.send error
        end
      }
      user.onclose {
        leave_room(user)
        @lounge.leave_lounge(user)
      }
      @table.add_user(user)
      # Send his location and table infos
      user.send(JoinResponseMessage.getJSON(user, @table.chairs))
      # publish user with location
      channel_msg = JoinChannelMessage.getJSON(user)
      @table.chairs.each do |position, usr|
        usr.send(channel_msg) if user.position != position
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
        success = @game.throw_tile(user, tile) # returns logical error if occurs
        if success
          @room_channel.push({ :action => :throw_tile,
                               :turn => @game.turn,
                               :tile => tile.to_s })
        else
          if user.position != @game.turn
            error_msg = GameMessage.getJSON(:error, nil, 'not your turn')
          else
            error_msg = GameMessage.getJSON(:error, nil, 'invalid move')
          end
        end
        
      when 'draw_tile'
        center = json['center']
        return RoomMessage.getJSON(:error, nil, 'messaging error') if center.nil? || @game.nil?
        tile = @game.draw_tile(user, !!center)
        if tile
          @table.chairs.each do |position, usr|
          usr.send({ :action =>       :draw_tile,
                     :tile =>         (position == user.position ? tile.to_s : nil),
                     :turn =>         @game.turn,
                     :center_count => @game.middle_tile_count })
          end
        else
          if user.position != @game.turn
            error_msg = GameMessage.getJSON(:error, nil, 'not your turn')
          else
            error_msg = GameMessage.getJSON(:error, nil, 'invalid move')
          end
        end
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
        success = @game.throw_to_finish(user, hand, tile)
        
        
        
        if success # Game ends
          @room_channel.push({ :action =>   :user_won,
                          :turn =>     user.position,
                          :username => user.username,
                          :hand =>     hand })
                          
          @table.chairs.each_value do |user|
            @game = nil
            leave_room(user)
            @lounge.join_lounge(user)
          end
        else
          if user.position != @game.turn
            error_msg = GameMessage.getJSON(:error, nil, 'not your turn')
          else
            error_msg = GameMessage.getJSON(:error, nil, 'invalid move')
          end
        end
        
      when 'leave_room'
        leave_room(user)
        @lounge.join_lounge(user)
      else # Send err
        error_msg = RoomMessage.getJSON(:error, nil, "messaging error")
      end
      error_msg
    end

  end
end