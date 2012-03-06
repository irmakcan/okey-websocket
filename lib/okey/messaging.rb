module Okey
  class ResponseMessage
    def self.action
      raise "Should be implemented"
    end
  end
  
  class AuthenticationMessage
    def self.getJSON(status, state_def, message)
      { :status => status, :payload => { :message => message }}.to_json
    end
  end
  
  class ChairStateMessage < ResponseMessage
    def self.action; 'chair_state'; end
    
    def self.getJSON(chairs)
      name_position = []
      chairs.each { |position, user|
        name_position << { :name => user.username, :position => position }
      }
      { :action => action, :users => name_position }.to_json
    end
  end
  
  class GameStartingMessage < ResponseMessage
    def self.action; 'game_start'; end
    
    # turn => true | false
    def self.getJSON(turn, center_tile_count, user_hand)
      { :action => action, :turn => turn, :center_count => center_tile_count , :hand => user_hand }.to_json
    end
  end
  
  class GameUpdateMessage < ResponseMessage
    def self.action; 'game_update'; end
    
    # turn => true | false
    def self.getJSON(turn, center_tile_count, changed_corner)
      { :action => action, :turn => turn, :center_count => center_tile_count, :changed_corner => changed_corner }.to_json
    end
  end
  
  # class MoveMessage < ResponseMessage
    # def self.action; 'move'; end
#     
  # end
  
end