module Okey
  class Lounge
    def initialize
      @player_count = 0
      @lounge_channel = EM::Channel.new
      @empty_rooms = []
      @full_rooms = []
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
      @player_count += 1
    end

    def leave_lounge(user)

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
        join_room(json['room_name'])
      when 'refresh_list'
        send_room_json(user)
      when 'create_room'
        room_name = json['room_name']
        if room_name.nil? || room_name.empty?
          raise ArgumentError, 'room name cannot be empty'
        end
        create_and_join_room(json['room_name'])
      else # Send err
        raise ArgumentError, 'messaging error'
      end
    end

    def join_room(room_name)

      #leave_lounge
    end

    def create_and_join_room(room_name)

    end

    def send_room_json(user)
      room_list = []
      @empty_rooms.each { |room|
        room_list << { :room_name => room.name, :count => room.count }
      }
      json = ({ :status => :lounge_update, :payload => { :list => room_list }}).to_json
      user.websocket.send(json)
    end

  end
end