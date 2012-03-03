module Okey
  class ResponseMessage
    def self.action
      raise "Should be implemented"
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
  
  # class MoveMessage < ResponseMessage
    # def self.action; 'move'; end
#     
  # end
  
end