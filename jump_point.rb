#!/bin/env ruby
# encoding: utf-8

require_relative 'lib/grid.rb'
require_relative 'lib/vector2.rb'

class MathHelper
  def self.sign(x)
    return 1 if x > 0
    return 0 if x == 0
    -1
  end
end

class Node
  attr_accessor :position, :parent, :target

  @@ADJACENT_MAP = { -1 => { -1 => [2, 3, 4],
                              0 => [4],
                              1 => [4, 5, 6] },
                      0 => { -1 => [2],
                              0 => [],
                              1 => [6] },
                      1 => { -1 => [0, 1, 2],
                              0 => [0],
                              1 => [0, 6, 7] } }

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
      direction = position.direction(parent.position)
      if direction == :diagonal
        @g_score = parent.G + 14 * (parent.position.x - @position.x).abs
      elsif direction == :horizontal
        @g_score = parent.G + 10 * (parent.position.x - @position.x).abs
      else
        @g_score = parent.G + 10 * (parent.position.y - @position.y).abs
      end

      @f_score = @h_score + @g_score
    end
  end

  def parent_dx
    MathHelper.sign(@position.x - @parent.position.x)
  end

  def parent_dy
    MathHelper.sign(@position.y - @parent.position.y)
  end

  def adjacent
    points = [Vector2.new(@position.x+1, @position.y),
              Vector2.new(@position.x+1, @position.y-1),
              Vector2.new(@position.x, @position.y-1),
              Vector2.new(@position.x-1, @position.y-1),
              Vector2.new(@position.x-1, @position.y),
              Vector2.new(@position.x-1, @position.y+1),
              Vector2.new(@position.x, @position.y+1),
              Vector2.new(@position.x+1, @position.y+1)]
    return points if @parent.nil?
    result = []

    @@ADJACENT_MAP[parent_dx][parent_dy].each { |i| result << points[i] }
    result
  end

  def find_successors(target, grid)
    successors = []

    # Find naturals
    adjacent.each do |node|
      dx = node.x - @position.x
      dy = node.y - @position.y
      jump_point = find_jump_point(@position.x, @position.y, dx, dy, target, grid)
      successors << Node.new(jump_point, self, target) if jump_point
    end

    # Find Forced
    unless parent.nil?
      direction = position.direction(@parent.position)
      if direction == :diagonal
        diagonal_forced(@position, parent_dx, parent_dy, grid).each do |point|
          successors << Node.new(point, self, target)
        end
      elsif direction == :horizontal
        horizontal_forced(@position, parent_dx, grid).each do |point|
          successors << Node.new(point, self, target)
        end
      else
        verticle_forced(@position, parent_dy, grid).each do |point|
          successors << Node.new(point, self, target)
        end
      end
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

  def diagonal_forced(position, dx, dy, grid)
    result = []
    result << Vector2.new(position.x+1, position.y+dy) if grid.blocked?(Vector2.new(position.x+1, position.y)) && !grid.blocked?(Vector2.new(position.x, position.y + dy)) && !grid.blocked?(Vector2.new(position.x+1, position.y + dy))
    result << Vector2.new(position.x-1, position.y+dy) if grid.blocked?(Vector2.new(position.x-1, position.y)) && !grid.blocked?(Vector2.new(position.x, position.y + dy)) && !grid.blocked?(Vector2.new(position.x-1, position.y + dy))
    result << Vector2.new(position.x+dx, position.y+1) if grid.blocked?(Vector2.new(position.x, position.y+1)) && !grid.blocked?(Vector2.new(position.x + dx, position.y)) && !grid.blocked?(Vector2.new(position.x + dx, position.y+1))
    result << Vector2.new(position.x+dx, position.y-1) if grid.blocked?(Vector2.new(position.x, position.y-1)) && !grid.blocked?(Vector2.new(position.x + dx, position.y)) && !grid.blocked?(Vector2.new(position.x + dx, position.y-1))
    result
  end

  def has_diagonal_forced(position, dx, dy, grid)
    !diagonal_forced(position, dx, dy, grid).empty?
  end

  def horizontal_forced(position, dx, grid)
    result = []
    return [] if grid.blocked?(Vector2.new(position.x + dx, position.y))
    result << Vector2.new(position.x+dx, position.y+1) if grid.blocked?(Vector2.new(position.x, position.y + 1)) && !grid.blocked?(Vector2.new(position.x+dx, position.y+1))
    result << Vector2.new(position.x+dx, position.y-1) if grid.blocked?(Vector2.new(position.x, position.y - 1)) && !grid.blocked?(Vector2.new(position.x+dx, position.y-1))
    result
  end

  def has_horizontal_forced(position, dx, grid)
    !horizontal_forced(position, dx, grid).empty?
  end

  def verticle_forced(position, dy, grid)
    result = []
    return [] if grid.blocked?(Vector2.new(position.x, position.y + dy))
    result << Vector2.new(position.x+1, position.y+dy) if grid.blocked?(Vector2.new(position.x + 1, position.y)) && !grid.blocked?(Vector2.new(position.x+1, position.y+dy))
    result << Vector2.new(position.x-1, position.y+dy) if grid.blocked?(Vector2.new(position.x - 1, position.y)) && !grid.blocked?(Vector2.new(position.x-1, position.y+dy))
    result
  end

  def has_verticle_forced(position, dy, grid)
    !verticle_forced(position, dy, grid).empty?
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
