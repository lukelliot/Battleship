load 'board.rb'
load 'ships.rb'

class Computer
  attr_reader :board, :ships_destroyed, :fleet, :ships_unplaced, :name

  ROBOT_NAMES = [
    'HAL',
    'Maria',
    'Johnny 5',
    'Mega-Man',
    'Bender Bending Rodriguez',
    'R2-D2',
    'WALL-E',
    'Roy Batty',
    'Optimus Prime',
    'T-800',
    'Ultron'
  ]

  def initialize
    @board = Board.new
    @name = ROBOT_NAMES.sample
    @ships_unplaced = Ship.types.dup
    @fleet = []
    @ships_destroyed = []
  end

  def populate
    until fleet.count == 5
      ship_type = ships_unplaced[-1]
      length = Ship.data[ship_type][:length]

      new_coords = random_coordinates(length)
      if valid_ship?(new_coords)
        @ships_unplaced.delete_at(-1)
        new_ship = Ship.new(ship_type).coordinates = new_coords
        @fleet << new_ship
      end
    end
  end

  def valid_ship?(coords)
    coords.all? do |xy|
      x, y = xy
      board.grid[y][x] == :~
    end
  end


  def random_series(length)
    start_of_length = rand(0..10-length)
    axis_coordinates = []
    length.times { |i| axis_coordinates << start_of_length + i }
    axis_coordinates

  end

  def random_coordinates(length)
    vert_or_horz = rand(0..1)
    axis2 = rand(0..9)
    random_series(length).map do |axis1|
      if vert_or_horz == 0
        [axis2, axis1]
      elsif vert_or_horz == 1
        [axis1, axis2]
      end
    end
  end
end
