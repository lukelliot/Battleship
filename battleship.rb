load 'interface.rb'
load 'computer.rb'
load 'human.rb'

class LoadOpponentError < ArgumentError
end

class Battleship
  attr_reader :p1, :p2, :current_player, :opponent, :winner

  def initialize
    @p1 = Human.new
    @p2 = nil

    @current_player = nil
    @opponent = nil
    @winner = nil
  end

  def play
    one_or_two_players
    get_names

    populate_boards

    randomize_player
    until won?
      current_player.attack(opponent)
      set_current_player
      press_enter { "Press ENTER to switch players." }
    end

    end_game

    play_again
  end

  def one_or_two_players
    case this_or_that("Player One", "Player Two")
    when "Player One"
      @p2 = Computer.new
    when "Player Two"
      @p2 = Human.new
    end
  end

  def get_names
    if p2.is_a?(Computer)
      begin
        TITLE.call
        puts "\n\nWhat is your name?\n"
        print " >> "
        input = gets
        raise ArgumentError if input == "\n"
        @p1.name = input.chomp
      rescue
        retry
      end
    else
      begin
        TITLE.call
        puts "\n\nWhat is PLAYER ONE's name?\n"
        print " >> "
        input = gets
        raise ArgumentError if input == "\n"
        @p1.name = input.chomp
      rescue
        retry
      end
      begin
        TITLE.call
        puts "\n\nWhat is PLAYER TWO's name?\n"
        print " >> "
        input = gets
        raise ArgumentError if input == "\n"
        @p2.name = input.chomp
      rescue
        retry
      end
    end
  end

  def populate_boards
    TITLE.call
    press_enter { "\n\n#{p1.name}'s turn to coordinate their fleet.\nPress ENTER to continue." }
    p1.populate
    TITLE.call
    press_enter { "\n\n#{p2.name}'s turn to coordinate their fleet.\nPress ENTER to continue." }
    p2.populate
  end


  def randomize_player
    TITLE.call
    case rand(0..1)
    when 0
      @current_player = p1
      @opponent = p2
      puts "\n\nPlayer 1 goes first."
    when 1
      @current_player = p2
      @opponent = p1
      puts "\n\nPlayer 2 goes first."
    end
    press_enter { "Press ENTER to begin the game." }
  end

  def set_current_player
    if @current_player == p1
      @current_player = p2
      @opponent = p1
    else
      @current_player = p1
      @opponent = p2
    end
  end

  def won?
    if p1.ships_destroyed.count == 5
      @winner = p2
      return true
    elsif p2.ships_destroyed.count == 5
      @winner = p1
      return true
    end
    false
  end

  def end_game
    TITLE.call
    puts "\n\n"
    puts " " * 10 << "#{@winner.name} is the winner!\n\n"
    puts "#{@p1.name}:"
    puts "\n" << "  " << "#{@p1.name}'s Destroyed Ships:\n"
    if p1.ships_destroyed.count > 0
      puts " | #{@p1.ships_destroyed.join( " | ")} |\n\n"
    else
      puts "\n\n"
    end

    puts "#{@p2.name}:"
    puts "\n" << "  " << "#{@p2.name}'s Destroyed Ships:\n"
    if p2.ships_destroyed.count > 0
      puts " | #{@p2.ships_destroyed.join( " | ")} |\n\n"
    else
      puts "\n\n"
    end
    press_enter
  end

  def play_again
    case this_or_that("Yes", "No") { puts "\nDo you want to play again?" }
    when "Yes"
      Battleship.new.play
    when "No"
      abort
    end
  end

  def self.reset
    Battleship.new
  end
end
