class InvalidShip < ArgumentError
end

class Ship
  attr_accessor :coords
  attr_reader :type, :length

  SHIPS = {
    'Destroyer' => { length: 2 },
    'Cruiser' => { length: 3 },
    'Submarine' => { length: 3 },
    'Battleship' => { length: 4 },
    'Aircraft Carrier' => { length: 5 }
  }

  def initialize(type)
    if SHIPS[type]
      @type = type
      @length = SHIPS[type][:length]
      @coords = []
    else
      raise InvalidShip
    end
  end

  def self.data
    SHIPS
  end

  def self.types
    SHIPS.map { |ship, _| ship }
  end
end
