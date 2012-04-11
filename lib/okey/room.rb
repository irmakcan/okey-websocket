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
      
    end

    def leave_room(user)
      user.ready = false #
      @table.remove(user.position)
      @lounge.destroy_room(self) if @table.empty?
      @room_channel.unsubscribe(user.sid)
      # publish leaved
      @room_channel.push(LeaveChannelMessage.getJSON(user.position))
      
      # Add Bot if game is already started
      if @table.state == :started
        bot = @table.create_bot(user.position)
        join_room(bot)
        bot.throw_callback do |tile|
          success = @table.throw_tile(bot, tile)
          raise "dsa" unless success
          push_throw(tile)
        end
        bot.draw_callback do |center|
          tile = @table.draw_tile(bot, center)
          push_draw(bot, tile) if tile
        end
        bot.finish_callback do |hand, tile|
          @table.throw_to_finish(bot, hand, tile)
          handle_finish(bot, hand)
        end
        
        if @table.turn == bot.position # TODO
          # Try draw
          
          # Throw
          
        end
        
      end
    end

    def count
      @table.user_count
    end

    def full?
      @table.full?
    end

    private
    
    def push_draw(user, tile)
      @table.chairs.each do |position, usr|
        usr.send({ :action =>       :draw_tile,
                   :tile =>         (position == user.position ? tile : nil),
                   :turn =>         @table.turn,
                   :center_count => @table.middle_tile_count })
      end
    end
    
    def push_throw(tile)
      @room_channel.push({ :action => :throw_tile,
                           :turn => @table.turn,
                           :tile => tile })
    end
    
    def handle_finish(user, hand)
      @room_channel.push({ :action =>   :user_won,
                           :turn =>     user.position,
                           :username => user.username,
                           :hand =>     hand })
                        
      @table.chairs.each_value do |usr|
        leave_room(usr)
        @lounge.join_lounge(usr) unless usr.bot?
      end
    end

    def handle_request(user, msg)
      json = nil
      begin
        json = JSON.parse(msg)
      rescue JSON::ParserError
        json = nil
      end
      
      return RoomMessage.getJSON(:error, nil, "Messaging error") if json.nil?
      
      error_msg = nil
      case json['action']
      when 'throw_tile'
        tile = TileParser.parse(json['tile'])
        return RoomMessage.getJSON(:error, nil, 'Messaging error') if tile.nil? || !@table.game_started?
        success = @table.throw_tile(user, tile) # returns logical error if occurs
        if success
          push_throw(tile)
        else
          if user.position != @table.turn
            error_msg = GameMessage.getJSON(:error, nil, 'Not your turn')
          else
            error_msg = GameMessage.getJSON(:error, nil, 'Invalid move')
          end
        end
        
      when 'draw_tile'
        center = json['center']
        return RoomMessage.getJSON(:error, nil, 'Messaging error') if center.nil? || !@table.game_started?
        tile = @table.draw_tile(user, !!center)
        if tile
          push_draw(user, tile)
        else
          if user.position != @table.turn
            error_msg = GameMessage.getJSON(:error, nil, 'Not your turn')
          else
            error_msg = GameMessage.getJSON(:error, nil, 'Invalid move')
          end
        end
      when 'ready'
        user.ready = true
        # start game
        @table.initialize_game if @table.full? && @table.all_ready? && @table.state == :waiting
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
        
        return RoomMessage.getJSON(:error, nil, 'Messaging error') if tile.nil? || !@table.game_started? || hand.nil? || hand.empty?
        success = @table.throw_to_finish(user, hand, tile)
        
        
        
        if success # Game ends
          handle_finish(user, hand)
        else
          if user.position != @table.turn
            error_msg = GameMessage.getJSON(:error, nil, 'Not your turn')
          else
            error_msg = GameMessage.getJSON(:error, nil, 'Invalid move')
          end
        end
        
      when 'leave_room'
        leave_room(user)
        @lounge.join_lounge(user)
      else # Send err
        error_msg = RoomMessage.getJSON(:error, nil, "Messaging error")
      end
      error_msg
    end
    
  end
end