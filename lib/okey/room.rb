module Okey
  class Room
    attr_reader :count, :name
    def initialize(lounge)
      @lounge = lounge
    end
    
    def join_room
      @count += 1
    end
    
    def leave_room
      @count -= 1
      if @count <= 0
        @lounge.destroy_room(self)
      end
    end

  end
end