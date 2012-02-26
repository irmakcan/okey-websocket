require File.expand_path('../user', __FILE__)

class Table
  
  def initialize
    # chairs[0] -> west, chairs[1] -> north
    @chairs = [nil, nil, nil, nil]
    @iterator = 0
  end
  
  # returns user position
  def add_user(user)
    @chairs.each_with_index do |val, index|
      if val.nil?
        @chairs[index] = user
        index
        break
      end
    end
    
  end
  
  def next
    @iterator += 1
    @iterator %= 4
    @chairs[@iterator]
  end
  
end