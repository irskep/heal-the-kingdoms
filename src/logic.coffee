_ = require 'underscore'
{Vector2, Rect2} = require './geometry'
{ImageStore, TileTypeStore, TILE_SIZE} = require './store'

# fuck you internet
window.requestAnimationFrame = (
  window.requestAnimationFrame ||
  window.mozRequestAnimationFrame ||
  window.webkitRequestAnimationFrame ||
  window.oRequestAnimationFrame);


class TileMap
  @worldPointToTileCoordinates: (worldPoint) ->
    worldPoint.pairDivide(TILE_SIZE)
  constructor: (@size, @getTile) ->
  render: (ctx, worldRect) ->
    worldRectMin = TileMap.worldPointToTileCoordinates(worldRect.getMin())
    worldRectMax = TileMap.worldPointToTileCoordinates(worldRect.getMax())
    startX = Math.max(0, worldRectMin.x)
    startY = Math.max(0, worldRectMin.y)
    endX = Math.min(@size.x, worldRectMax.x)
    endY = Math.min(@size.y, worldRectMax.y)
    for y in [startY..endY]
      for x in [startX..endX]
        @getTile(x, y).render(ctx, TILE_SIZE.pairMultiply({x, y}))
    null


init = (canvas) ->
  imageStore = new ImageStore ->
    tileTypeStore = new TileTypeStore(imageStore)
    map = new TileMap new Vector2(20, 20), (x, y) ->
      # TODO: map reading logic
      return tileTypeStore.tileTypes.test1

    ctx = canvas.getContext('2d')
    requestId = requestAnimationFrame ->
      map.render(ctx, new Rect2(0, 0, canvas.width, canvas.height))


module.exports = {init}