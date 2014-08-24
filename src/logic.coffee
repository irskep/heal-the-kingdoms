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
color = require './color'
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
  @worldCoordsToTileCoords: (worldPoint, floorOrCeil='floor') ->
    worldPoint.pairDivide(TILE_SIZE)[floorOrCeil]()
  @tileCoordsToWorldCoords: (tilePoint) ->
    tilePoint.pairMultiply(TILE_SIZE)

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
    worldRectMin = TileMap.worldCoordsToTileCoords(worldRect.getMin(), 'floor')
    worldRectMax = TileMap.worldCoordsToTileCoords(worldRect.getMax(), 'ceil')
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
  getIsPath: (position) -> @getValue(position) == 1
  getIsDoor: (position) -> @getValue(position) == 3


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

  getCenter: -> @worldPosition.add(TILE_SIZE.multiply(0.5))

  update: (dt) ->
    _.each @behaviors, (b) => b.update(dt)

  render: (ctx) -> @subject.render(ctx, @worldPosition)


class TileMovementBehavior
  constructor: (@tilePosition, @speed) ->

  init: (@actor) ->
    @actor.worldPosition = TileMap.tileCoordsToWorldCoords(@tilePosition)
    @targetWorldPosition = TileMap.tileCoordsToWorldCoords(@tilePosition)
    @decide()

  setTilePosition: (newTilePosition) ->
    @tilePosition = newTilePosition
    @targetWorldPosition = TileMap.tileCoordsToWorldCoords(@tilePosition)

  update: (dt) ->
    speedVector = TILE_SIZE.multiply(@speed)
    unless @actor.worldPosition.isEqual(@targetWorldPosition)
      @actor.worldPosition = approach(
        @actor.worldPosition, @targetWorldPosition, speedVector.multiply(dt))

    if @getShouldDecide()
      @decide()

  getShouldDecide: -> @actor.worldPosition.isEqual(@targetWorldPosition)

  decide: -> throw "not implemented"


class KeyboardControlledTileMovementBehavior extends TileMovementBehavior
  constructor: (@logicalMap, @tilePosition, @speed=4) ->
    super(@tilePosition, @speed)

  decide: ->
    change = new Vector2(0, 0)
    w = (x, y) =>
      p = @tilePosition.add(new Vector2(x, y))
      @logicalMap.getIsPath(p) or @logicalMap.getIsDoor(p)
    if (keyboard.getIsKeyDown(window.keyboardSettings.playerLeft) and w(-1, 0))
      change.x -= 1
    if (keyboard.getIsKeyDown(window.keyboardSettings.playerRight) and w(1, 0))
      change.x += 1
    if (keyboard.getIsKeyDown(window.keyboardSettings.playerUp) and w(0, -1))
      change.y -= 1
    if (keyboard.getIsKeyDown(window.keyboardSettings.playerDown) and w(0, 1))
      change.y += 1

    # can cheat with diagonals unless we check for it
    if change.x and change.y and !w(change.x, change.y)
      change.x = 0
      change.y = 0
    @setTilePosition @tilePosition.add(change)


class RandomWalkTileMovementBehavior extends TileMovementBehavior

  constructor: (@logicalMap, @tilePosition, @speed=3) ->
    super(@tilePosition, @speed)
    @greenLightTime = Date.now()

  decide: ->
    return unless Date.now() >= @greenLightTime
    possibleChanges = [
      new Vector2(-1, 0),
      new Vector2(1, 0),
      new Vector2(0, -1),
      new Vector2(0, 1),
    ]
    chosenChange = _.choice [null].concat _.filter possibleChanges, (change) =>
      @logicalMap.getIsPath(@tilePosition.add(change))

    if chosenChange
      @setTilePosition @tilePosition.add chosenChange
    else
      @greenLightTime = Date.now() + _.random(500, 2000)


init = (canvas) ->
  canvasSize = new Vector2(canvas.width, canvas.height)

  imageStore = new ImageStore ->
    drawableMap = new DrawableTileMap(
      imageStore.images['tiles'], testMapDrawData)
    logicalMap = new LogicalTileMap(testMapLogicalData)

    actors = []

    npcSubject = new TwoFrameSubject(
      imageStore, 'Player', new Vector2(0, 0), 500)
    actors.push new Actor(npcSubject, [
      new RandomWalkTileMovementBehavior(logicalMap, new Vector2(5, 5)),
    ])

    playerSubject = new TwoFrameSubject(
      imageStore, 'Player', new Vector2(1, 0), 500)
    player = new Actor(playerSubject, [
      new KeyboardControlledTileMovementBehavior(
        logicalMap, new Vector2(10, 10)),
    ])
    actors.push player

    ctx = canvas.getContext('2d')

    update = (dt) ->
      _.each actors, (a) -> a.update(dt)

    render = ->
      ctx.fillStyle = color.darkgreen
      ctx.fillRect(0, 0, canvasSize.x, canvasSize.y);
      ctx.save()
      mapCenter = player.getCenter().floor()

      ctx.translate(
        -mapCenter.x + canvasSize.x / 2,
        -mapCenter.y + canvasSize.y / 2)

      drawableMap.render(ctx, Rect2.fromCenter(mapCenter, canvasSize))
      _.each actors, (a) -> a.render(ctx)
      ctx.restore()

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