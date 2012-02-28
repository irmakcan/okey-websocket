require 'singleton'

module Okey
  class Lounge
    include Singleton
    def initialize
      @player_count = 0
      @lounge_channel = EM::Channel.new
      @empty_rooms = []
      @full_rooms = []
      
      EventMachine.add_periodic_timer(5) do
        json = []
        @empty_rooms.each { |room| 
          json << ({:action => :lounge_update, :payload => { :room => room.name, :count => room.count }}).to_json
        }
        @lounge_channel.push(json) unless json.empty?
      end
    end

    def join_lounge(user)
      user.websocket.onmessage{ |msg|
        begin
          json = JSON.parse(msg)
          handle_request(json)
        rescue JSON::ParserError
          result = { :status => :error, :payload => { :message => "messaging error" }}.to_json
        rescue ArgumentError => message
          result = { :status => :error, :payload => { :message => message }}.to_json
        end
      }
      # subscribe
      sid = @lounge_channel.subscribe do |msg|
        user.websocket.send msg
      end
      user.subscribed_channel_id = sid
    end

    def leave_lounge(user)
      @lounge_channel.unsubscribe(user.subscribed_channel_id)
    end
    
    private
      def handle_request(json)
        room_name = json[:room_name]
        if room_name.nil? || room_name.empty?
          raise ArgumentError, 'room name cannot be empty'
        end
        case json[:action]
        when :join_room
          join_room(json[:room_name])
        when :create_room
          create_and_join_room(json[:room_name])
        else # Send err
          raise ArgumentError, 'messaging error'
        end
      end
    
    
      def join_room(room_name)
        
        #leave_lounge
      end
      
      def create_and_join_room(room_name)
        
      end

  end
end