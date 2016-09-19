require 'byebug'
require 'io/console'
load 'interface.rb'
load 'board.rb'
load 'ships.rb'

class Human
  attr_accessor :name
  attr_reader :board, :fleet, :ships_destroyed, :ships_unplaced

  def initialize(name = "Gandalf")
    @name = name
    @board = Board.new

    @ships_unplaced = Ship.types.dup
    @fleet = []
    @ships_destroyed = []
  end

  def populate
    until @fleet.count == 5
      case add_remove
      when "Add Ship"
        add_ship
      when "Remove Ship"
        remove_ship
      end
    end

    case confirm_remove
    when "Confirm"
      return
    when "Remove Ship"
      remove_ship
      populate
    end
  end

  def add_remove
    this_or_that("Add Ship", "Remove Ship") do
      if @fleet.count > 0
        puts "\n| #{@fleet.map { |ship| ship.type}.join( " | ")} |"
      else
        puts "\n\n"
      end
      board.render_grid("#{self.name}'s Fleet")
    end
  end

  def confirm_remove
    this_or_that("Confirm", "Remove Ship") do
      puts "\n| #{@fleet.map { |ship| ship.type}.join( " | ")} |"
      board.render_grid("#{self.name}'s Fleet")
      puts "\n" << " " * 14 << "Confirm placement of these ships?"
    end
  end

  def add_ship
    if @ships_unplaced.empty?
      return press_enter { "You have a full fleet! Press ENTER to continue." }
    end

    type = scroll_selection(@ships_unplaced)

    new_ship = Ship.new(type)

    set_coords(new_ship)

    @fleet << new_ship
    @fleet = @fleet.sort_by { |ship| ship.length }
  end

  def scroll_selection(ships)
  i = 0
  loop do
    display(ships, i)
    case raw_keystroke_data
    when "\r"
      return ships.delete_at(i)
    when "\e[C" #Right Arrow key
      i += 1
      i = i == ships.count ? 0 : i
    when "\e[D" #Left Arrow Key
      i -= 1
      i = i < 0 ? (ships.count-1) : i
    when "\177" #BACKSPACE
      self.populate
    when "\u0003"
      "Abort!"
      exit 0
    end
  end
  end

  def display(ships, idx)
    title_and_grid

    ship = ships[idx]
    length = Ship.data[ship][:length]
    ship_graphic = "|" << " S |" * length

    puts %Q(\nUse ARROW LEFT and ARROW RIGHT to select a ship.\n\n)
    puts "Press DELETE to go back to the Add/Remove menu."
    puts %Q(Press ENTER to make a selection.\n)
    puts %Q(\n#{idx+1}] #{ship} -- #{length} x 1)
    puts %Q(   _#{"____" * length})
    puts %Q( > #{ship_graphic})
    puts %Q(   -#{"----" * length})
  end

  def set_coords(ship)
    default_placement(ship)
    rotated = false
    loop do
      begin
        title_and_grid
        place_ship_text

        case raw_keystroke_data
        when "\r" #RETURN key
          select_ship(ship)
          return press_enter
        when " " #SPACEBAR
          rotate(ship, rotated)
          rotated = rotated ? false : true
        when "\e[A" #Up Arrow
          shift(ship, 1, y: true)
        when "\e[B" #Down Arrow
          shift(ship, -1, y: true)
        when "\e[C" #Right Arrow
          shift(ship, 1, x: true)
        when "\e[D" #Left Arrow
          shift(ship, -1, x: true)
        when "\177" #BACKSPACE
          back_to_populate(ship)
        when "\u0003"
          "Abort!"
          exit 0
        end
      rescue InvalidShip
        "Invalid move"
        retry
      end
    end
  end

  def place_ship_text
    puts "\nUse the ARROW KEYS to move your ship."
    puts "Use SPACEBAR to rotate your ship.\n\n"
    puts "Press DELETE to return to the previous menu."
    puts "Press ENTER to set position."
  end

  def default_placement(ship)
    l = ship.length

    board.grid.each_with_index do |row, y|
      row.each_cons(l).with_index do |cons, x|
        break if x + l == 11
        #break if the set length would go over the edge of the board
        if cons.all? { |mark| mark == :~ }
          #checks for an open space
          l.times do |length|
            ship.coords << [(x + length), y]
            #Then set the coordinates of the ship instance
          end
          return board.mark_ship(ship.coords, :S)
          #places ship onto grid
        end
      end
    end
  end

  def select_ship(ship)
    board.mark_ship(ship.coords, :F)
    title_and_grid
    article = ship.type[0] == "A" ? "an" : "a"
    puts "\nYou've added #{article} #{ship.type.upcase} to your fleet.\n\n"
  end

  def shift(ship, shift, options)
    board.mark_ship(ship.coords, :~)
    #Takes the ship off of the board to avoid "seeing" itself when avoiding other ships
    new_coords = ship.coords.dup

    loop do
      new_coords.map! do |xy|
        #iterates new_coords until it finds a valid space
        x, y = xy

        if options[:y]
          y -= shift
          unless y.between?(0, 9)
            board.mark_ship(ship.coords, :S)
            raise InvalidShip
          end
        elsif options[:x]
          x += shift
          unless x.between?(0, 9)
            board.mark_ship(ship.coords, :S)
            raise InvalidShip
          end
        end
        #shifts the coordinates accordinate to option[axis]

        [x, y]
      end


      next if any_ships_in_the_way?(new_coords)

      if off_the_board?(new_coords)
        board.mark_ship(ship.coords, :S)
        raise InvalidShip
      elsif valid_ship?(new_coords)
        break
      end
    end

    board.mark_ship(new_coords, :S)
    ship.coords = new_coords
  end

  def off_the_board?(coords)
    coords.any? { |xy| xy.any?(&:nil?) }
  end

  def any_ships_in_the_way?(coords)
    coords.any? do |xy|
      x, y = xy
      board.grid[y][x] == :s
    end
  end

  def valid_ship?(coords)
    coords.all? do |xy|
      x, y = xy
      board.grid[y][x] == :~
    end
  end

  def rotate(ship, rotated)
    board.mark_ship(ship.coords, :~)
    new_coords = ship.coords.dup
    center = (ship.length - 1) / 2
    # finds fulcrum index
    fulcrum = new_coords[center]
    fulcrum_x, fulcrum_y = fulcrum

    if rotated
      (0...center).each do |i|
        x, y = fulcrum_x + (center - i), fulcrum_y
        valid_rotation(x, y, ship)
        new_coords[i] =x, y
      end
      (center + 1...ship.length).each do |i|
        x, y = fulcrum_x - (i - center), fulcrum_y
        valid_rotation(x, y, ship)
        new_coords[i] = x, y
      end
    else
      (0...center).each do |i|
        x, y = fulcrum_x, fulcrum_y - (center - i)
        valid_rotation(x, y, ship)
        new_coords[i] = x, y
      end
      (center + 1...ship.length).each do |i|
        x, y = fulcrum_x, fulcrum_y + (i - center)
        valid_rotation(x, y, ship)
        new_coords[i] = x, y
      end
    end

    if valid_ship?(new_coords)
      board.mark_ship(new_coords, :S)
      ship.coords = new_coords
    else
      board.mark_ship(ship.coords, :S)
      raise InvalidShip
    end
  end

      def valid_rotation(x, y, ship)
        unless x.between?(0, 9) && y.between?(0, 9)
          board.mark_ship(ship.coords, :S)
          raise InvalidShip
        end
      end

  def back_to_populate(ship)
    board.mark_ship(ship.coords, :~)
    ship.coords.clear
    @ships_unplaced << ship.type
    @ships_unplaced.sort_by { |type, data| data[:length] }
    self.populate
  end

  def remove_ship
    if @fleet.empty?
      return press_enter { "You haven't placed any ships! Press ENTER to continue." }
    end

    @ships_unplaced << preview(@fleet)
    @ships_unplaced = @ships_unplaced.sort_by do |ship_type|
      Ship.data[ship_type][:length]
    end
  end
  def preview(ships)
    i = 0
    loop do
      board.mark_ship(ships[i].coords, :S)

      title_and_grid
      remove_ship_prompt(ships[i])

      case raw_keystroke_data
      when "\r"
        board.mark_ship(ships[i].coords, :~)
        ships[i].coords.clear
        return ships.delete_at(i).type
      when "\e[C" #Right Arrow key
        board.mark_ship(ships[i].coords, :F)
        i += 1
        i = i == ships.count ? 0 : i
      when "\e[D" #Left Arrow Key
        board.mark_ship(ships[i].coords, :F)
        i -= 1
        i = i < 0 ? (ships.count-1) : i
      when "\177" #BACKSPACE
        board.mark_ship(ships[i].coords, :F)
        self.populate
      when "\u0003"
        "Abort!"
        exit 0
      end
    end
  end

  def remove_ship_prompt(ship)
    puts "\nUse LEFT ARROW and RIGHT ARROW to cycle through your fleet.\n\n"
    puts "Remove your #{ship.type.upcase}?\n\n"
    puts "Press DELETE to return to the previous menu."
    puts "Press ENTER to make a selection."
  end

  def attack(opponent)
    begin
      title_and_display(opponent)
      coords = get_coords
      return if backdoor(opponent, coords)

      if opponent.board.hit?(coords)
        x, y = Board.convert(coords)
        destroyed = damage_ship(opponent, x, y)
        title_and_display(opponent)

        if destroyed
          puts "#{opponent.name}'s #{opponent.ships_destroyed.last} has been destroyed!"
          opponent.ships_destroyed.sort!
        else
          puts "\n\nHit!\n\n"
        end
      else
        title_and_display(opponent)
        puts "\n\nMiss!\n\n"
      end
    rescue
      retry
    end
  end

  def get_coords
    puts "\nEnter coordinates you'd like to target in the format 'XY'."
    puts "Then press ENTER"
    puts "Example: B7\n\n"
    print " >> "
    gets.chomp
  end

  def backdoor(opponent, input)
    if input == "SOLVE"
      opponent.fleet.each do |ship|
        opponent.ships_destroyed << ship.type
      end
      return true
    end
    false
  end

  def damage_ship(opponent, *hit)
    opponent.fleet.each do |ship|
      ship.coords.each_index do |i|
        if ship.coords[i] == [*hit]
          ship.coords.delete_at(i)

          if ship.coords.empty?
            opponent.ships_destroyed << ship.type
            opponent.fleet.delete(ship)
            return true
          end

          return false
        end
      end
    end
  end

  def title_and_grid
    TITLE.call
    if @fleet.count > 0
      puts "\n| #{@fleet.map { |ship| ship.type}.join( " | ")} |"
    else
      puts "\n\n"
    end
    board.render_grid("#{self.name}'s Fleet")
  end

  def title_and_display(opponent)
    TITLE.call
    opponent.board.render_display("#{self.name}'s Turn")
    if opponent.ships_destroyed.count > 0
      puts "\n" << "  " << "#{opponent.name}'s Destroyed Ships:\n"
      puts " | #{opponent.ships_destroyed.join( " | ")} |\n\n"
    end
  end
end
