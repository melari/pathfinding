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

  @@NATURAL_SEARCH_DIRECTIONS_MAP = { -1 => { -1 => [2, 3, 4],
                                               0 => [4],
                                               1 => [4, 5, 6] },
                                       0 => { -1 => [2],
                                               0 => [],
                                               1 => [6] },
                                       1 => { -1 => [0, 1, 2],
                                               0 => [0],
                                               1 => [0, 6, 7] } }

  def self.find_jump_point(parent, position, target, grid)
    node = Node.new(position, parent, target)
    return nil if grid.blocked?(node.position)
    return node if node.position == target

    if node.direction_from_parent == :diagonal
      return node if node.has_diagonal_forced?(grid)

      if !Node.find_jump_point(node, Vector2.new(node.position.x + node.parent_dx, node.position.y), target, grid).nil? ||
         !Node.find_jump_point(node, Vector2.new(node.position.x, node.position.y + node.parent_dy), target, grid).nil?
        return node
      end
    elsif node.direction_from_parent == :horizontal
      return node if node.has_horizontal_forced?(grid)
    else # Vertical
      return node if node.has_vertical_forced?(grid)
    end

    # This node is not a jump point, continue along the path.
    next_position = Vector2.new(node.position.x + node.parent_dx, node.position.y + node.parent_dy)
    Node.find_jump_point(parent, next_position, target, grid)
  end

  def initialize(position, parent, target)
    @position = position
    @parent = parent
    @target = target
  end

  def calculate_scores
    @h_score = ((target.x - position.x).abs + (target.y - position.y).abs) * 10

    if @parent.nil?
      @g_score = 0
      @f_score = @h_score
    else
      if direction_from_parent == :diagonal
        @g_score = @parent.G + 14 * (@parent.position.x - @position.x).abs
      elsif direction_from_parent == :horizontal
        @g_score = @parent.G + 10 * (@parent.position.x - @position.x).abs
      else
        @g_score = @parent.G + 10 * (@parent.position.y - @position.y).abs
      end

      @f_score = @h_score + @g_score
    end
  end

  def parent_dx
    @parent_dx ||= MathHelper.sign(@position.x - @parent.position.x)
  end

  def parent_dy
    @parent_dy ||= MathHelper.sign(@position.y - @parent.position.y)
  end

  def direction_from_parent
    @parent_direction ||= @position.direction(@parent.position)
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
  end

  def natural_search_directions
    points = adjacent
    return points if @parent.nil?

    result = []
    @@NATURAL_SEARCH_DIRECTIONS_MAP[parent_dx][parent_dy].each { |i| result << points[i] }
    result
  end

  def find_successors(target, grid)
    successors = []

    # Find naturals
    natural_search_directions.each do |direction|
      jump_point = Node.find_jump_point(self, direction, target, grid)
      successors << jump_point if jump_point
    end

    # Find Forced
    unless parent.nil?
      if direction_from_parent == :diagonal
        diagonal_forced(grid).each do |point|
          successors << Node.new(point, self, target)
        end
      elsif direction_from_parent == :horizontal
        horizontal_forced(grid).each do |point|
          successors << Node.new(point, self, target)
        end
      else
        vertical_forced(grid).each do |point|
          successors << Node.new(point, self, target)
        end
      end
    end

    successors
  end

  def diagonal_forced(grid)
    dx = parent_dx
    dy = parent_dy

    result = []
    result << Vector2.new(@position.x+1, @position.y+dy) if grid.blocked?(Vector2.new(@position.x+1, @position.y)) && !grid.blocked?(Vector2.new(@position.x, @position.y + dy)) && !grid.blocked?(Vector2.new(@position.x+1, @position.y + dy))
    result << Vector2.new(@position.x-1, @position.y+dy) if grid.blocked?(Vector2.new(@position.x-1, @position.y)) && !grid.blocked?(Vector2.new(@position.x, @position.y + dy)) && !grid.blocked?(Vector2.new(@position.x-1, @position.y + dy))
    result << Vector2.new(@position.x+dx, @position.y+1) if grid.blocked?(Vector2.new(@position.x, @position.y+1)) && !grid.blocked?(Vector2.new(@position.x + dx, @position.y)) && !grid.blocked?(Vector2.new(@position.x + dx, @position.y+1))
    result << Vector2.new(@position.x+dx, @position.y-1) if grid.blocked?(Vector2.new(@position.x, @position.y-1)) && !grid.blocked?(Vector2.new(@position.x + dx, @position.y)) && !grid.blocked?(Vector2.new(@position.x + dx, @position.y-1))
    result
  end

  def horizontal_forced(grid)
    dx = parent_dx
    dy = parent_dy

    result = []
    return [] if grid.blocked?(Vector2.new(@position.x + dx, @position.y))
    result << Vector2.new(@position.x+dx, @position.y+1) if grid.blocked?(Vector2.new(@position.x, @position.y + 1)) && !grid.blocked?(Vector2.new(@position.x+dx, @position.y+1))
    result << Vector2.new(@position.x+dx, @position.y-1) if grid.blocked?(Vector2.new(@position.x, @position.y - 1)) && !grid.blocked?(Vector2.new(@position.x+dx, @position.y-1))
    result
  end

  def vertical_forced(grid)
    dx = parent_dx
    dy = parent_dy

    result = []
    return [] if grid.blocked?(Vector2.new(@position.x, @position.y + dy))
    result << Vector2.new(@position.x+1, @position.y+dy) if grid.blocked?(Vector2.new(@position.x + 1, @position.y)) && !grid.blocked?(Vector2.new(@position.x+1, @position.y+dy))
    result << Vector2.new(@position.x-1, @position.y+dy) if grid.blocked?(Vector2.new(@position.x - 1, @position.y)) && !grid.blocked?(Vector2.new(@position.x-1, @position.y+dy))
    result
  end

  def has_diagonal_forced?(grid)
    !diagonal_forced(grid).empty?
  end

  def has_horizontal_forced?(grid)
    !horizontal_forced(grid).empty?
  end

  def has_vertical_forced?(grid)
    !vertical_forced(grid).empty?
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
