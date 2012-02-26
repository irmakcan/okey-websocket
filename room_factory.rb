require File.expand_path('../room', __FILE__)

class RoomFactory
  
  def initialize()
    @counter = 0 # Endless counter
    @rooms = []
    @current_room = create_room
    @rooms << @current_room
  end
  
  def get_room
    if @current_room.nil? || @current_room.player_count >= 4
      @current_room = create_room
      @rooms << @current_room
    end
    @current_room
  end
  
  def destroy_room(room)
    @rooms.delete room
  end
  
  private
    
    def create_room
      @counter += 1;
      Room.new("room#{@counter}")
    end
end