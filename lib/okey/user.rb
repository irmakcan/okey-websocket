module Okey
  class Player
    attr_accessor :username, :position, :afk_count, :points
    attr_reader :websocket
    
    def initialize
      @afk_count = 0
      @points = 0
    end
    
    def bot?
      false
    end
    
    def start_timer(action, hand = nil)
      @timer = EventMachine::Timer.new(Okey::Server.play_interval) do
        @afk_count += 1
        if @afk_count >= 4
          message = { :action => 'leave_room' }
        else
          if action == :draw
            # Draw random
            message = { :action => 'draw_tile', :center => [true, false].sample }
          elsif action == :throw
            # Throw random
            message = { :action => 'throw_tile', :tile => hand.sample }
          end
        end
        @websocket.trigger_on_message(message.to_json) if @websocket
      end
    end
    
    def cancel_timer
      @timer.cancel if @timer
      @timer = nil
    end
    
  end
  
  class OkeyBot < Player
    attr_accessor :sid
    
    def initialize()
      super()
      @username = "Okey Bot"
      @ready = true
    end
    
    def init_bot(hand, indicator, left_tile)
      @indicator = indicator
      @left_tile = left_tile
      @hand = hand.dup
    end
    
    def bot?
      true
    end
    
    def force_play
      if @hand.length == 14
        play_draw(@left_tile)
      else
        play_throw
      end
    end
    
    def play_draw(left_tile)
      # if left_tile.nil? must draw from center
      # For now let's always draw center tile
      @draw_callback.call(true) # center = true
    end
    
    def play_throw
    # for now let's always throw the last tile in the hand
      last_index = @hand.length - 1
      tile = @hand.delete_at(last_index)
      @throw_callback.call(tile)
    end
    
    def send(hash)
      EM.next_tick do
        if hash[:status] == :throw_tile && hash[:turn] == @position
          tile = hash[:tile]
          play_draw(tile)
        elsif hash[:status] == :draw_tile && hash[:turn] == @position
          tile = hash[:tile]
          @hand.push(tile)
          play_throw
        elsif hash[:status] == 'game_start'
          init_bot(hash[:hand], hash[:indicator], nil)
          if(hash[:turn] == @position)
            EM::next_tick{force_play}
          end
        elsif hash[:status] == :join_room
          @position = hash[:position]
        end
      end
    end
    
    def onmessage(&blk)

    end
    
    def onclose(&blk)
  
    end
    
    def draw_callback(&block)
      @draw_callback = block
    end
    
    def throw_callback(&block)
      @throw_callback = block
    end
    
    def finish_callback(&block)
      @finish_callback = block
    end
    
    def ready?
      @ready
    end
    
    def ready=(state)
      @ready = state
    end
    
  end
  
  class User < Player
    attr_accessor :sid
    
    def initialize(websocket)
      super()
      @websocket = websocket
      @ready = false
      @timer = nil
    end

    def ready?
      @ready
    end
    
    def ready=(state)
      @ready = state
    end

    def authenticated?
      @authenticated
    end
    def authenticated=(auth)
      @authenticated = auth
    end

    def send(hash)
      @websocket.send(hash.to_json)
    end
    
    def onmessage(&blk)
      @websocket.onmessage(&blk)
    end
    
    def onclose(&blk)
      @websocket.onclose(&blk)
    end
    
    def state
      @websocket.state
    end

  end
end