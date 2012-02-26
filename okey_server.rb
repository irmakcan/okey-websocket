require 'rubygems'
require 'bundler/setup'
require 'em-websocket'
require 'em-hiredis'

require File.expand_path('../room', __FILE__)
require File.expand_path('../user', __FILE__)
require File.expand_path('../room_factory', __FILE__)

class OkeyServer
  
  def start_server(options)
    
    # @channel = EM::Channel.new
  
    # @redis = EM::Hiredis.connect
    # puts 'subscribing to redis'
    # @redis.subscribe('ws') # subscribe rooms
    # @redis.on(:message){|channel, message|
      # puts "redis -> #{channel}: #{message}"
      # channel.push message # TODO to json
      # #@channel.push message
    # }
  
    # Creates a websocket listener
    
    # @rooms = []
    # @count = 1
    # @current_room = Room.new("room#{@count}")
    @room_factory = RoomFactory.new
    
    
    EventMachine::WebSocket.start(options) do |ws|
      
      puts 'Establishing websocket'
      ws.onopen do
        user = User.new(ws)
        
        puts 'client connected'
        puts 'subscribing to channel'
        
        room = @room_factory.get_room
        room.join(user)
        
        
        # sid = @channel.subscribe do |msg|
          # puts "sending: #{msg}"
          # ws.send msg
          # puts "sid: #{sid}"
        # end
  
        # ws.onmessage { |msg|
          # @channel.push "<#{sid}>: #{msg}"
        # }
   
        # ws.onclose {
          # @channel.unsubscribe(sid)
        # }
      end
    end
  end
  
end

EM.run do
  OkeyServer.new.start_server(:host => '0.0.0.0', :port => 8080, :debug => true)
end