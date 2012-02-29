
module Okey
  class Chair
    CARDINALS = [:west, :north, :east, :south]
    def self.next(cardinal_point)
      index = CARDINALS.index(cardinal_point)
      CARDINALS[(index + 1)%4]
    end
  end
end