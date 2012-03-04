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
        ""
      }
      #user.websocket.onclose {}
      user.position = @table.add_user(user)
      # publish user with location
      @room_channel.push(ChairStateMessage.getJSON(@table.chairs))
      
    end

    def leave_room(user)
      @table.remove(user.position)
      if @table.empty?
        @lounge.destroy_room(self)
      end
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


  end
end