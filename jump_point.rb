#!/bin/env ruby
# encoding: utf-8

require_relative 'lib/grid.rb'
require_relative 'lib/vector2.rb'

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
    [Vector2.new(@position.x+1, @position.y),
     Vector2.new(@position.x+1, @position.y-1),
     Vector2.new(@position.x, @position.y-1),
     Vector2.new(@position.x-1, @position.y-1),
     Vector2.new(@position.x-1, @position.y),
     Vector2.new(@position.x-1, @position.y+1),
     Vector2.new(@position.x, @position.y+1),
     Vector2.new(@position.x+1, @position.y+1)]
  end

  def find_successors(target, grid)
    successors = []
    adjacent.each do |node|
      dx = node.x - @position.x
      dy = node.y - @position.y
      jump_point = find_jump_point(@position.x, @position.y, dx, dy, target, grid)
      successors << Node.new(jump_point, self, target) if jump_point
    end
    successors
  end

  def find_jump_point(sx, sy, dx, dy, target, grid)
    new_position = Vector2.new(sx + dx, sy + dy)
    return nil if grid.blocked?(new_position)
    return new_position if new_position == target

    if dx != 0 && dy != 0 # Diagonal case
      if has_diagonal_forced(new_position, dx, dy, grid)
        return new_position
      end

      if !find_jump_point(new_position.x, new_position.y, dx, 0, target, grid).nil? ||
         !find_jump_point(new_position.x, new_position.y, 0, dy, target, grid).nil?
        return new_position
      end
    elsif dx != 0 # Horizontal case
      if has_horizontal_forced(new_position, dx, grid)
        return new_position
      end
    else # Verticle case
      if has_verticle_forced(new_position, dy, grid)
        return new_position
      end
    end

    # No jump point found, continue along the path.
    find_jump_point(new_position.x, new_position.y, dx, dy, target, grid)
  end

  def has_diagonal_forced(position, dx, dy, grid)
    return true if grid.blocked?(Vector2.new(position.x+1, position.y)) && !grid.blocked?(Vector2.new(position.x, position.y + dy)) && !grid.blocked?(Vector2.new(position.x+1, position.y + dy))
    return true if grid.blocked?(Vector2.new(position.x-1, position.y)) && !grid.blocked?(Vector2.new(position.x, position.y + dy)) && !grid.blocked?(Vector2.new(position.x-1, position.y + dy))
    return true if grid.blocked?(Vector2.new(position.x, position.y+1)) && !grid.blocked?(Vector2.new(position.x + dx, position.y)) && !grid.blocked?(Vector2.new(position.x + dx, position.y+1))
    return true if grid.blocked?(Vector2.new(position.x, position.y-1)) && !grid.blocked?(Vector2.new(position.x + dx, position.y)) && !grid.blocked?(Vector2.new(position.x + dx, position.y-1))
    false
  end

  def has_horizontal_forced(position, dx, grid)
    return false if grid.blocked?(Vector2.new(position.x + dx, position.y))
    grid.blocked?(Vector2.new(position.x, position.y + 1)) || grid.blocked?(Vector2.new(position.x, position.y - 1))
  end

  def has_verticle_forced(position, dy, grid)
    return false if grid.blocked?(Vector2.new(position.x, position.y + dy))
    grid.blocked?(Vector2.new(position.x + 1, position.y)) || grid.blocked?(Vector2.new(position.x - 1, position.y))
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
    node.find_successors(@target, @grid).each do |adjacent|
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
        break
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
