require File.expand_path('../table', __FILE__)

class Room
  attr_reader :room_name, :player_count
  
  
  
  def initialize(room_name)
    raise 'Room name cannot be empty' if room_name.nil?
    @room_name = room_name
    @player_count = 0;
    @table = Table.new
    
    @room_channel = EM::Channel.new
    @redis = EM::Hiredis.connect
    raise "Cannot connected to redis server" if @redis.connected?
    @redis.subscribe(@room_name)
    
    @redis.on(:message){|channel, message|
      puts "redis -> #{channel}: #{message}"
      @room_channel.push(message)
      #channel.push message # TODO to json
      #@channel.push message
    }
  end
  
  def join(user)
    @player_count += 1
    watch_room(user)
    @table.add_user(user)
    user.websocket.onmessage {
      # do something TODO
      # game play
    }
    user.websocket.onclose {
      # TODO activate computer
      @player_count -= 1
      if @player_count <= 0
        destroy_room
      end
    }
    # place him to a chair
    # notify everybody
    
  end
  
  def watch_room(user)
    @room_channel.subscribe do |msg|
      user.websocket.send msg
    end
  end
  
  private
  
    def destroy_room
      # TODO
      puts "closing room"
      # @redis.unsubscribe(@room_name)
      @redis.close_connection
    end
end