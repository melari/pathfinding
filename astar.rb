#!/bin/env ruby
# encoding: utf-8

class Grid
  def self.GRID_SIZE
    19
  end

  def initialize
    @grid = [[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
             [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
             [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
             [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
             [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
             [1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1],
             [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1],
             [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1],
             [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1],
             [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1],
             [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1],
             [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1],
             [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1],
             [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1],
             [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1],
             [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1],
             [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
             [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
             [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
             [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
    (0..Grid.GRID_SIZE).each do |y|
      (0..Grid.GRID_SIZE).each do |x|
        @grid[x][y] = @grid[x][y] == 1 ? true : false
      end
    end
  end

  def player=(player)
    @player = player
  end

  def draw
    result = ""
    (0..Grid.GRID_SIZE).each do |y|
      (0..Grid.GRID_SIZE).each do |x|
        position = Vector2.new(x, y)
        if @player.position == position
          result += "## "
        elsif @player.target == position
          result += "XX "
        elsif @player.path.include? position
          result += "oo "
        else
          found = nil
          @player.open.each do |node|
            if node.position == position
              found = ".. "
            end
          end
          @player.closed.each do |node|
            if node.position == position
              found = "** "
            end
          end
          if found.nil?
            result += blocked?(position) ? "██ " : "   "
          else
            result += found
          end
        end
      end
      result += "\n"
    end

    puts result
  end

  def blocked?(position)
    @grid[position.y][position.x]
  end
end

class Vector2
  attr_accessor :x, :y

  def initialize(x, y)
    @x = x
    @y = y
  end

  def ==(other)
    @x == other.x && @y == other.y
  end

  def direction(other)
    return :diagonal if other.x != x && other.y != y
    return :horizontal if other.x == x && other.y != y
    return :vertical if other.x != x && other.y == y
    return :none
  end

  def to_s
    "(#{@x}, #{@y})"
  end
end

class Node
  attr_accessor :position, :parent, :target

  def initialize(position, parent, target)
    @position = position
    @parent = parent
    @target = target
  end

  def calculate_scores
    @h_score = ((target.x - position.x).abs + (target.y - position.y).abs) * 10

    if parent.nil?
      @g_score = 0
      @f_score = @h_score
    else
      if position.direction(parent.position) == :diagonal
        @g_score = parent.G + 14
      else
        @g_score = parent.G + 10
      end

      @f_score = @h_score + @g_score
    end
  end

  def adjacent
    [Node.new(Vector2.new(@position.x+1, @position.y), self, @target),
     Node.new(Vector2.new(@position.x+1, @position.y-1), self, @target),
     Node.new(Vector2.new(@position.x, @position.y-1), self, @target),
     Node.new(Vector2.new(@position.x-1, @position.y-1), self, @target),
     Node.new(Vector2.new(@position.x-1, @position.y), self, @target),
     Node.new(Vector2.new(@position.x-1, @position.y+1), self, @target),
     Node.new(Vector2.new(@position.x, @position.y+1), self, @target),
     Node.new(Vector2.new(@position.x+1, @position.y+1), self, @target)]
  end

  def to_s
    "#{@position.to_s} H:#{@h_score} G:#{@g_score} F:#{@f_score}"
  end

  def ==(other)
    other.position == @position
  end

  def G
    @g_score
  end

  def H
    @h_score
  end

  def F
    @f_score
  end
end


class Player
  attr_accessor :position, :target, :completed, :path
  attr_accessor :open, :closed

  @grid = nil
  @open = []
  @closed = []
  @completed = false
  @path = []

  def initialize(x, y)
    @position = Vector2.new(x, y)
    @path = []
  end

  def set_target(x, y)
    @target = Vector2.new(x, y)
  end

  def pathfind_start(grid)
    @grid = grid

    @open = []
    @closed = []
    @completed = false

    insert_into_open(Node.new(@position, nil, @target))
  end

  def pathfind_step
    node = @open.shift
    return pathfind_end(nil) if node.nil?

    @closed << node
    node.adjacent.each do |adjacent|
      next if @grid.blocked?(adjacent.position)
      next if @closed.include?(adjacent)
      next if @open.include?(adjacent)
      pathfind_end(adjacent) if adjacent.position == @target
      insert_into_open(adjacent)
    end
  end

  def pathfind_end(winner)
    @completed = true
    @path = []
    return puts "No path." if winner.nil?

    node = winner
    while !node.nil?
      path << node.position
      node = node.parent
    end
  end

  def insert_into_open(new_node)
    new_node.calculate_scores

    @open.each_index do |index|
      node = @open[index]
      if new_node.F <= node.F
        @open.insert(index, new_node)
        return
      end
    end

    @open << new_node
  end
end


grid = Grid.new
player = Player.new(5, 10)
player.set_target(18, 10)
grid.player = player

player.pathfind_start(grid)
while (!player.completed)
  player.pathfind_step
  grid.draw
end
