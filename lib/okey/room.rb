module Okey
  class Room
    attr_reader :count, :name
    def initialize(lounge, room_name, user)
      @count = 0
      @lounge = lounge
      @name = room_name
      join_room(user)
    end
    
    def join_room(user)
      @count += 1
    end
    
    def leave_room
      @count -= 1
      if @count <= 0
        @lounge.destroy_room(self)
      end
    end
    
    def full?
      @count >= 4
    end

  end
end