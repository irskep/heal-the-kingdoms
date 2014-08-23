_ = require 'underscore'
{Vector2, Rect2} = require './geometry'
store = require './store'
keyboard = require './keyboard'
{
  ImageStore, TILE_SIZE, CharacterType, drawTile, drawTile, SRC_TILE_SIZE
} = store
testMapDrawData = require './maps/test'
testMapLogicalData = require './maps/test_logical'

# fuck you internet
window.requestAnimationFrame = (
  window.requestAnimationFrame ||
  window.mozRequestAnimationFrame ||
  window.webkitRequestAnimationFrame ||
  window.oRequestAnimationFrame);


class TileMap
  @worldCoordsToTileCoords: (worldPoint) -> worldPoint.pairDivide(TILE_SIZE)
  @tileCoordsToWorldCoords: (tilePoint) -> tilePoint.pairMultiply(TILE_SIZE)

  constructor: (@mapData) ->
    @size = new Vector2(
      @mapData.layers[0][0].length, @mapData.layers[0].length)


class DrawableTileMap extends TileMap

  constructor: (@mapTileImage, args...) ->
    super(args...)
    imageColumns = @mapTileImage.width / SRC_TILE_SIZE.x
    @layers = _.map @mapData.layers, (layer) ->
      _.map layer, (row) ->
        _.map row, (index) ->
          index -= 1
          new Vector2(index % imageColumns, Math.floor(index / imageColumns))

  render: (ctx, worldRect) ->
    worldRectMin = TileMap.worldCoordsToTileCoords(worldRect.getMin())
    worldRectMax = TileMap.worldCoordsToTileCoords(worldRect.getMax())
    startX = Math.max(0, worldRectMin.x)
    startY = Math.max(0, worldRectMin.y)
    endX = Math.min(@size.x, worldRectMax.x)
    endY = Math.min(@size.y, worldRectMax.y)

    for layer in [0...@layers.length]
      for y in [startY...endY]
        for x in [startX...endX]
          position = TILE_SIZE.pairMultiply({x, y})
          drawTile(@mapTileImage, @layers[layer][y][x], ctx, position)
    null


class LogicalTileMap extends TileMap

  constructor: (args...) ->
    super(args...)

  getValue: (position) -> @layers[0][position.y][position.x]


SPEED = 4  # tiles per second
SPEED_PX = TILE_SIZE.multiply(SPEED)


approach = (currentPosition, targetPosition, maxMove) ->
  newPosition = currentPosition.clone()
  if currentPosition.x < targetPosition.x
    newPosition.x = Math.min(currentPosition.x + maxMove.x, targetPosition.x)
  if currentPosition.x > targetPosition.x
    newPosition.x = Math.max(currentPosition.x - maxMove.x, targetPosition.x)
  if currentPosition.y < targetPosition.y
    newPosition.y = Math.min(currentPosition.y + maxMove.y, targetPosition.y)
  if currentPosition.y > targetPosition.y
    newPosition.y = Math.max(currentPosition.y - maxMove.y, targetPosition.y)
  newPosition


class Actor
  constructor: (@type, @tilePosition) ->
    @worldPosition = TileMap.tileCoordsToWorldCoords(@tilePosition)
    @targetWorldPosition = TileMap.tileCoordsToWorldCoords(@tilePosition)
    @decide()

  render: (ctx) -> @type.render(ctx, @worldPosition)

  setTilePosition: (newTilePosition) ->
    @tilePosition = newTilePosition
    @targetWorldPosition = TileMap.tileCoordsToWorldCoords(@tilePosition)

  update: (dt) ->
    unless @worldPosition.isEqual(@targetWorldPosition)
      @worldPosition = approach(
        @worldPosition, @targetWorldPosition, SPEED_PX.multiply(dt))

    if @getShouldDecide()
      @decide()

  getShouldDecide: -> @worldPosition.isEqual(@targetWorldPosition)

  decide: ->
    tilePositionChange = new Vector2(0, 0)
    if keyboard.getIsKeyDown('left')
      tilePositionChange.x -= 1
    if keyboard.getIsKeyDown('up')
      tilePositionChange.y -= 1
    if keyboard.getIsKeyDown('right')
      tilePositionChange.x += 1
    if keyboard.getIsKeyDown('down')
      tilePositionChange.y += 1

    @setTilePosition @tilePosition.add tilePositionChange


init = (canvas) ->
  imageStore = new ImageStore ->
    drawableMap = new DrawableTileMap(
      imageStore.images['tiles'], testMapDrawData)
    logicalMap = new LogicalTileMap(testMapLogicalData)

    playerType = new CharacterType(
      imageStore, 'Player', new Vector2(0, 0), 500)
    player = new Actor(playerType, new Vector2(10, 10))

    ctx = canvas.getContext('2d')

    update = (dt) ->
      player.update(dt)

    render = ->
      drawableMap.render(ctx, new Rect2(0, 0, canvas.width, canvas.height))
      player.render(ctx)

    lastTime = Date.now()
    run = ->
      newTime = Date.now()
      dt = (newTime - lastTime) / 1000
      lastTime = newTime
      update(dt)
      render()
      requestAnimationFrame(run)
      null
    requestAnimationFrame(run)


module.exports = {init}