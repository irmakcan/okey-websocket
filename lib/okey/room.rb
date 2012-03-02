module Okey
  class Room
    attr_reader :count, :name
    def initialize(lounge, room_name, user)
      @table = Table.new
      @lounge = lounge
      @name = room_name
      join_room(user)
    end
    
    def join_room(user)
      user.websocket.onmessage { |msg| 
        
      }
      #user.websocket.onclose {}
      @table.add_user(user)
    end
    
    def leave_room(user)
      @table.remove_user(user)
      if @table.empty?
        @lounge.destroy_room(self)
      end
      @lounge.join_lounge(user)
    end
    
    def full?
      @table.full?
    end

  end
end