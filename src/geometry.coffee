class Vector2
  constructor: (@x, @y) ->
    throw "NaN" if isNaN(@x) or isNaN(@y)
  multiply: (factor) -> new Vector2(@x * factor, @y * factor)
  pairMultiply: (other) -> new Vector2(@x * other.x, @y * other.y)
  pairDivide: (other) -> new Vector2(@x / other.x, @y / other.y)
  isEqual: (other) -> @x == other.x and @y == other.y
  clone: -> new Vector2(@x, @y)

  add: (other) -> new Vector2(@x + other.x, @y + other.y)


class Rect2
  constructor: (@xmin, @ymin, @xmax, @ymax) ->
    throw "NaN" if isNaN(@xmin) or isNaN(@ymin) or isNaN(@xmax) or isNaN(@ymax)
  getMin: -> new Vector2(@xmin, @ymin)
  getMax: -> new Vector2(@xmax, @ymax)


module.exports = {Vector2, Rect2}