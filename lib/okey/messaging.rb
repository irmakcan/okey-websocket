module Okey
  class ResponseMessage
    def self.action
      raise "Should be implemented"
    end
  end
  
  class AuthenticationMessage
    def self.getJSON(status, state_def, message)
      { :status => status, :message => message }
    end
  end
  
  class LoungeMessage
    def self.getJSON(status, state_def, message)
      { :status => status, :message => message }
    end
  end
  
  class RoomMessage
    def self.getJSON(status, state_def, message)
      { :status => status, :message => message }
    end
  end
  
  class GameMessage
    def self.getJSON(status, state_def, message)
      { :status => status, :message => message }
    end
  end

  
  class RoomChannelMessage
    # def self.getJSON(status, state_def, message)
      # { :status => status, :message => message }.to_json
    # end
  end
  
  # class ChairStateMessage < ResponseMessage
    # def self.action; 'chair_state'; end
#     
    # def self.getJSON(chairs)
      # name_position = []
      # chairs.each { |position, user|
        # name_position << { :name => user.username, :position => position }
      # }
      # { :status => action, :users => name_position }.to_json
    # end
  # end
  
  class JoinResponseMessage < ResponseMessage
    def self.action; 'join_room'; end
    
    def self.getJSON(user, chairs)
      name_position = []
      chairs.each { |pos, usr|
        name_position << { :name => usr.username, :position => pos, :points => usr.points } if user.position != pos
      }
      { :status => action, :position => user.position, :users => name_position, :play_timeout => Okey::Server.play_interval }
    end
  end
  
  class JoinChannelMessage < ResponseMessage
    def self.action; 'new_user'; end
    
    def self.getJSON(user)
      { :status => action, :position => user.position, :username => user.username, :points => user.points }
    end
  end
  
  class LeaveChannelMessage < ResponseMessage
    def self.action; 'user_leave'; end
    
    def self.getJSON(position)
      { :status => action, :position => position }
    end
  end
  
  class GameStartingMessage < ResponseMessage
    def self.action; 'game_start'; end
    
    # turn => true | false
    def self.getJSON(turn, center_tile_count, user_hand, indicator_tile)
      { :status => action, 
        :turn => turn, 
        :center_count => center_tile_count, 
        :hand => user_hand, 
        :indicator => indicator_tile.to_s 
      }
    end
  end
  
  class GameUpdateMessage < ResponseMessage
    def self.action; 'game_update'; end
    
    # turn => true | false
    def self.getJSON(turn, center_tile_count, changed_corner)
      { :status => action, :turn => turn, :center_count => center_tile_count, :changed_corner => changed_corner }
    end
  end
  
  # class MoveMessage < ResponseMessage
    # def self.action; 'move'; end
#     
  # end
  
end