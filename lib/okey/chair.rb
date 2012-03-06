
module Okey
  class Chair
    POSITIONS = [:south, :east, :north, :west]
    def self.next(position_index)
      index = POSITIONS.index(position_index)
      POSITIONS[(index + 1)%4]
    end
  end
end