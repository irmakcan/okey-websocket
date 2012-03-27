require 'set'

module Okey
  class Lounge
    def initialize(user_controller)
      @user_controller = user_controller
      @empty_rooms = {}
      @full_rooms = {}
      @players = Set.new
    end

    def join_lounge(user)
      user.onmessage{ |msg|
        error = handle_request(user, msg)
        if error
          user.send error
        end
      }
      user.onclose {
        @players.delete(user)
      }
      # subscribe
      user.send({ :status => :success, :message => "Authentication success" })
      @players << user
    end

    def leave_lounge(user)
      @players.delete(user)
    end
     

    def destroy_room(room)
      r = @empty_rooms.delete(room.name)
      @full_rooms.delete(room.name) if r.nil?
    end

    private

    def handle_request(user, msg)
      json = nil
      begin
        json = JSON.parse(msg)
      rescue JSON::ParserError
        json = nil
      end
      
      return LoungeMessage.getJSON(:error, nil, 'Messaging error') if json.nil?
      error = nil
      case json['action']
      when 'join_room'
        room_name = json['room_name']
        return LoungeMessage.getJSON(:error, nil, 'Room name cannot be empty') if room_name.nil? || room_name.empty?
        error = join_room(json['room_name'], user)
      when 'refresh_list'
        send_room_json(user)
      when 'create_room'
        room_name = json['room_name']
        unless room_name.nil?
          room_name = room_name.slice(/\S+(\s*\S+)*/); # Get rid of the spaces
        end
        return LoungeMessage.getJSON(:error, nil, 'Room name cannot be blank') if room_name.nil? || room_name.empty?
        error = create_and_join_room(room_name, user)
      when 'leave_lounge'
        leave_lounge(user)
        @user_controller.subscribe(user)
      else # Send err
        return LoungeMessage.getJSON(:error, nil, 'Messaging error')
      end
      error
    end

    def join_room(room_name, user)
      room = @empty_rooms[room_name]
      
      return LoungeMessage.getJSON(:error, nil, (@full_rooms[room_name].nil? ? 'Cannot find the room' : 'Room is full')) unless room
      room.join_room(user)
      if room.full?
        @full_rooms.merge!({ room.name => @empty_rooms.delete(room.name) })
      end
      nil
    end

    def create_and_join_room(room_name, user)
      return LoungeMessage.getJSON(:error, nil, 'Room name is already taken') if @empty_rooms.has_key?(room_name) || @full_rooms.has_key?(room_name)
      
      room = Room.new(self, room_name)
      room.join_room(user)
      @empty_rooms.merge!({ room_name => room })
      
      nil
    end

    def send_room_json(user)
      room_list = []
      @empty_rooms.each_value { |room|
        room_list << { :room_name => room.name, :count => room.count }
      }
      json = { :status => :lounge_update, :player_count => @players.length, :list => room_list }
      user.send(json)
    end

  end
end