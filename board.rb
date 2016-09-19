load 'interface.rb'

class TargetError < ArgumentError
end

class Board
  attr_reader :display, :grid

  X_AXIS = {
    'A' => 0,
    'B' => 1,
    'C' => 2,
    'D' => 3,
    'E' => 4,
    'F' => 5,
    'G' => 6,
    'H' => 7,
    'I' => 8,
    'J' => 9
  }

  Y_AXIS = {
    '1' => 0,
    '2' => 1,
    '3' => 2,
    '4' => 3,
    '5' => 4,
    '6' => 5,
    '7' => 6,
    '8' => 7,
    '9' => 8,
    '10' => 9,
  }

  def initialize
    @grid = Board.default
    @display = Board.default
    # ^^ For the opponent to see their attacks via opponent#display
  end

  def self.default
    Array.new(10) { Array.new(10) { :~ } }
  end

  def self.convert(coords)
    x, y = coords[0], coords[1..-1]
    [X_AXIS[x.upcase], Y_AXIS[y]]
  end

  def valid_move?(coords)
    /[A-Ja-j][1-9]/.match(coords) ||
    /[A-Ja-j]10/.match(coords)
  end

  def mark_ship(coords, mark)
    coords.each do |coordinate|
      x, y = coordinate
      @grid[y][x] = mark
    end
  end

  def hit?(coords)
    if valid_move?(coords)
      l, n = Board.convert(coords)

      if @grid[n][l] == :~
        @grid[n][l], @display[n][l] = :/, :/
        return false
      elsif @grid[n][l] == :F
        @grid[n][l], @display[n][l] = :X, :X
        return true
      else
        press_enter { "\nYou've already targeted this location. Press ENTER to continue."}
        raise TargetError
      end
    else
      press_enter { "\nInvalid ship coordinates. Press ENTER to continue." }
      raise TargetError
    end
  end

  # GRID COMPONENTS

  def render_grid(title = "Allied Fleet")
    print "\n"
    tab_title(10); puts ":: #{title} :: "
    @grid.each_with_index do |row, i|
      render_row(row, i)
    end
    render_letters
  end

  def render_display(title = "Enemy Fleet")
    print "\n"
    tab_title(10); puts ":: #{title} :: "
    @display.each_with_index do |row, i|
      render_row(row, i)
    end
    render_letters
  end

  def grid_ln
    print "_" * 46 << "\n"
  end

  def bottom_ln
    print " " * 5 << "^" * 41 << "\n"
  end

  def render_row(row, i)
    tab; grid_ln
    if i == 9
      tab; print %Q(| 10 | #{row.join(" | ")} |\n)
      tab; grid_ln
    else
      tab; print %Q(| #{i+1}  | #{row.join(" | ")} |\n)
    end
  end

  def render_letters
    tab; print %Q(     | #{X_AXIS.keys.join(" | ")} |\n)
    tab; bottom_ln
  end

  def tab
    print " " * 8
  end

  def tab_title(x)
    print "  " * x
  end
end
