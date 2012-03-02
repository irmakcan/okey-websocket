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
      user.websocket.onmessage{ |msg|
        begin
          json = JSON.parse(msg)
          handle_request(user, json)
        rescue JSON::ParserError
          result = { :status => :error, :payload => { :message => "messaging error" }}.to_json
          user.websocket.send(result)
        rescue ArgumentError => message
          result = { :status => :error, :payload => { :message => message }}.to_json
          user.websocket.send(result)
        end
      }
      # user.websocket.onclose {}
      # subscribe
      user.websocket.send({ :status => :success, :payload => { :message => "authentication success" }}.to_json)
      @players << user
    end

    def leave_lounge(user)
      @players.delete(user)
      @user_controller.subscribe(user)
    end
     

    def destroy_room(room)
      @empty_rooms.delete(room)
    end

    private

    def handle_request(user, json)
      case json['action']
      when 'join_room'
        room_name = json['room_name']
        if room_name.nil? || room_name.empty?
          raise ArgumentError, 'room name cannot be empty'
        end
        join_room(json['room_name'], user)
      when 'refresh_list'
        send_room_json(user)
      when 'create_room'
        room_name = json['room_name']
        if room_name.nil? || room_name.empty?
          raise ArgumentError, 'room name cannot be empty'
        end
        create_and_join_room(room_name, user)
      when 'leave_lounge'
        leave_lounge(user)
      else # Send err
        raise ArgumentError, 'messaging error'
      end
    end

    def join_room(room_name, user)
      room = @empty_rooms[room_name]
      if room
        room.join_room(user)
        if room.full?
          @full_rooms.merge!({ room.name => @empty_rooms.delete(room.name) })
        end
      else
        if @full_rooms[room_name]
          raise ArgumentError, 'room is full'
        else
          raise ArgumentError, 'cannot find the room'
        end
      end
    end

    def create_and_join_room(room_name, user)
      if @empty_rooms.has_key?(room_name) || @full_rooms.has_key?(room_name)
        raise ArgumentError, 'room name is already taken'
      else
        room = Room.new(self, room_name)
        room.join_room(user)
        @empty_rooms.merge!({ room_name => room })
      end
      
    end

    def send_room_json(user)
      room_list = []
      @empty_rooms.each { |room|
        room_list << { :room_name => room.name, :count => room.count }
      }
      json = ({ :status => :lounge_update, :payload => { :player_count => @players.length, :list => room_list }}).to_json
      user.websocket.send(json)
    end

  end
end