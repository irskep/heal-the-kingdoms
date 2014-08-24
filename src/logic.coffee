_ = require 'underscore'

_.choice = (options, weights = null, totalWeight = null) ->
  return null unless options?.length
  return options[_.random(0, options.length - 1)] unless weights

  total = totalWeight or _.sum(weights)
  r = Math.random() * total
  upto = 0
  for i in [0..weights.length]
     if upto + weights[i] > r
        return options[i]
     upto += weights[i]
  throw "Shouldn't get here"


{Vector2, Rect2} = require './geometry'
store = require './store'
keyboard = require './keyboard'
{
  ImageStore, TILE_SIZE, TwoFrameSubject, drawTile, drawTile, SRC_TILE_SIZE
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
    @data = @mapData.layers[0]

  getValue: (position) ->
    if @data[position.y]? and @data[position.y][position.x]?
      @data[position.y][position.x]
    else
      null
  getIsWalkable: (position) -> @getValue(position) == 1


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
  constructor: (@subject, @behaviors) ->
    @worldPosition = null  # you must set me
    _.each @behaviors, (b) => b.init(this)

  update: (dt) ->
    _.each @behaviors, (b) => b.update(dt)

  render: (ctx) -> @subject.render(ctx, @worldPosition)


class TileMovementBehavior
  constructor: (@tilePosition) ->

  init: (@actor) ->
    @actor.worldPosition = TileMap.tileCoordsToWorldCoords(@tilePosition)
    @targetWorldPosition = TileMap.tileCoordsToWorldCoords(@tilePosition)
    console.log 'boom'
    @decide()

  setTilePosition: (newTilePosition) ->
    @tilePosition = newTilePosition
    @targetWorldPosition = TileMap.tileCoordsToWorldCoords(@tilePosition)

  update: (dt) ->
    SPEED = 4  # tiles per second
    SPEED_PX = TILE_SIZE.multiply(SPEED)
    unless @actor.worldPosition.isEqual(@targetWorldPosition)
      @actor.worldPosition = approach(
        @actor.worldPosition, @targetWorldPosition, SPEED_PX.multiply(dt))

    if @getShouldDecide()
      @decide()

  getShouldDecide: -> @actor.worldPosition.isEqual(@targetWorldPosition)

  decide: -> throw "not implemented"


class RandomWalkTileMovementBehavior extends TileMovementBehavior

  constructor: (@logicalMap, args...) ->
    super(args...)

  decide: ->
    possibleChanges = [
      new Vector2(-1, 0),
      new Vector2(1, 0),
      new Vector2(0, -1),
      new Vector2(0, 1),
    ]
    chosenChange = _.choice _.filter possibleChanges, (change) =>
      @logicalMap.getIsWalkable(@tilePosition.add(change))
    return unless chosenChange

    @setTilePosition @tilePosition.add chosenChange


init = (canvas) ->
  imageStore = new ImageStore ->
    drawableMap = new DrawableTileMap(
      imageStore.images['tiles'], testMapDrawData)
    logicalMap = new LogicalTileMap(testMapLogicalData)

    actors = []

    npcSubject = new TwoFrameSubject(
      imageStore, 'Player', new Vector2(0, 0), 500)
    actors.push new Actor(npcSubject, [
      new RandomWalkTileMovementBehavior(logicalMap, new Vector2(10, 10)),
    ])

    ctx = canvas.getContext('2d')

    update = (dt) ->
      _.each actors, (a) -> a.update(dt)

    render = ->
      drawableMap.render(ctx, new Rect2(0, 0, canvas.width, canvas.height))
      _.each actors, (a) -> a.render(ctx)

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