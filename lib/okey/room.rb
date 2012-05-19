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
      user.afk_count = 0
      if @table.game_started? && !user.bot?
        bot = nil
        pos = nil
        @table.chairs.each do |position, usr|
          if usr.bot?
            bot = usr
            pos = position
            break
          end
        end
        @room_channel.unsubscribe(bot.sid)
        @table.remove(pos)
      end
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
      user.cancel_timer
      @table.remove(user.position)
      @room_channel.unsubscribe(user.sid)
      
      if @table.user_count <= 0
        @table.state = :finished
        @table.chairs.each_value do |player|
          player.cancel_timer
        end
        @lounge.destroy_room(self)
      else
        # publish leaved if game not started
        @room_channel.push(LeaveChannelMessage.getJSON(user.position)) unless @table.game_started?
        
        # Add Bot if game is already started
        if @table.game_started?
          Okey::Server.update_points(user, -8)
          
          bot = OkeyBot.new
          @table.init_bot(bot, user.position)
          join_room(bot)
          register_bot_callbacks(bot)
          
          if @table.turn == bot.position # TODO
            bot.force_play()
          end
          
        end
      end
      
    end

    def count
      @table.user_count
    end

    def full?
      @table.full?
    end
    
    def has_bot?
      @table.has_bot?
    end
    
    def chairs
      @table.chairs 
    end

    private
    
    def push_draw(user, tile)
      @table.chairs.each do |position, usr|
        usr.send({ :status =>       :draw_tile,
                   :tile =>         (position == user.position ? tile : nil),
                   :turn =>         @table.turn,
                   :center_count => @table.middle_tile_count })
      end
    end
    
    def push_throw(tile)
      @room_channel.push({ :status => :throw_tile,
                           :turn => @table.turn,
                           :tile => tile })
    end
    
    def handle_finish(user, hand)
      if user.nil? # push tie
        @room_channel.push({ :status =>   :user_won,
                             :turn =>     nil,
                             :username => nil,
                             :hand =>     nil })
        @table.chairs.each_value do |usr|
          Okey::Server.update_points(usr, -4) unless usr.bot?
        end
        
      else
        @room_channel.push({ :status =>   :user_won,
                             :turn =>     user.position,
                             :username => user.username,
                             :hand =>     hand })
        @table.chairs.each_value do |usr|
          Okey::Server.update_points(usr, (usr == user ? 10 : -5)) unless usr.bot?
        end
      end
                        
      @table.chairs.each_value do |usr|
        leave_room(usr)
        @lounge.join_lounge(usr) unless usr.bot?
      end
    end
    
    def push_chat(user, message)
      @room_channel.push({ :status =>   :chat,
                           :position => user.position,
                           :message =>  message })
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
          if @table.middle_tile_count <= 0
            # Tilebag run out of tiles (declare tie)
            handle_finish(nil, nil)
          else
            push_throw(tile)
          end
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
        if @table.game_started?
          user.send(GameStartingMessage.getJSON(@table.turn,
                                              @table.tile_bag.center_tile_left,
                                              @table.tile_bag.hands[user.position],
                                              @table.tile_bag.indicator))
        else
          # start game
          @table.initialize_game if @table.full? && @table.all_ready? && @table.state == :waiting
        end
      when 'force_start'
        if @table.state == :waiting && !@table.full?
          until @table.full? do
            bot = OkeyBot.new
            register_bot_callbacks(bot)
            @lounge.join_room(@name, bot)
          end
          @table.initialize_game if @table.full? && @table.all_ready? && @table.state == :waiting
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
      when 'chat'
        push_chat(user, json['message']) if json['message']
      else # Send err
        error_msg = RoomMessage.getJSON(:error, nil, "Messaging error")
      end
      error_msg
    end
    
    def register_bot_callbacks(bot)
      bot.throw_callback do |tile|
        success = @table.throw_tile(bot, tile)
        raise "Should always success (Bot throw tile) #{self.inspect}" unless success
        
        if @table.middle_tile_count <= 0
          # Tilebag run out of tiles (declare tie)
          handle_finish(nil, nil)
        else
          push_throw(tile)
        end
      end
      bot.draw_callback do |center|
        tile = @table.draw_tile(bot, center)
        push_draw(bot, tile) if tile
      end
      bot.finish_callback do |hand, tile|
        @table.throw_to_finish(bot, hand, tile)
        handle_finish(bot, hand)
      end
    end
    
  end
end