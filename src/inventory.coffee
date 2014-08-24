_ = require 'underscore'
{Vector2, Rect2} = require './geometry'
{TILE_SIZE, SRC_TILE_SIZE} = require './subject'

class InventoryItem
  constructor: (@tileSubject, @id, @label) ->


module.exports = {InventoryItem}