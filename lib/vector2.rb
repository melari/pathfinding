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
    return :horizontal if other.x != x && other.y == y
    return :vertical if other.x == x && other.y != y
    return :none
  end

  def to_s
    "(#{@x}, #{@y})"
  end
end
