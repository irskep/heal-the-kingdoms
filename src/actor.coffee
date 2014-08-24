Bacon = require 'baconjs'
_ = require 'underscore'
{Vector2, Rect2} = require './geometry'
color = require './color'
keyboard = require './keyboard'
{TileMap} = require './tileMap'
{TILE_SIZE} = require './subject'


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
    return if @deathTime
    _.each @behaviors, (b) => b.update(dt)

  render: (ctx) ->
    if @deathTime
      ctx.save()
      timeSinceDeath = Math.min(Date.now() - @deathTime, 2000)
      ctx.globalAlpha = 1 - (timeSinceDeath / 2000)
    @subject.render(ctx, @worldPosition)
    ctx.restore() if @deathTime


class TileMovementBehavior
  constructor: (@tilePosition, @speed=2) ->

  init: (@actor) ->
    @actor.worldPosition = TileMap.tileCoordsToWorldCoords(@tilePosition)
    @actor.tilePositionUpdates = new Bacon.Bus()
    @targetWorldPosition = TileMap.tileCoordsToWorldCoords(@tilePosition)
    @decide()

  setTilePosition: (newTilePosition) ->
    @tilePosition = newTilePosition
    @actor.tilePosition = @tilePosition
    @actor.tilePositionUpdates.push @tilePosition
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

  constructor: (@logicalMap, @tilePosition, @speed=2) ->
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


class AttackBehavior extends TileMovementBehavior

  constructor: ({@logicalMap, @tilePosition, @getTarget, @onHit}) ->
    super(@tilePosition)
    @moveTime = Date.now()
    #@stabOn = 0
    #@stabOff = 0

  update: (dt) ->
    super(dt)

    target = @getTarget()
    return unless target
    distanceToTarget = (
      target.worldPosition.subtract(@actor.worldPosition).getLength())
    if distanceToTarget < TILE_SIZE.x / 3
      @onHit(target)

  decide: ->
    return unless Date.now() >= @moveTime
    maybeChanges = _.shuffle [
      new Vector2(-1, 0),
      new Vector2(1, 0),
      new Vector2(0, -1),
      new Vector2(0, 1),
    ]
    possibleChanges = _.filter maybeChanges, (change) =>
      @logicalMap.getIsPath(@tilePosition.add(change))

    target = @getTarget()
    return unless target
    chosenChange = _.min possibleChanges, (change) =>
      target.tilePosition.subtract(@tilePosition.add(change)).getLength()
    debugger if keyboard.getIsKeyDown('q')

    if chosenChange
      @setTilePosition @tilePosition.add chosenChange
    else
      @moveTime = Date.now() + _.random(250)


module.exports = {
  Actor, KeyboardControlledTileMovementBehavior,
  RandomWalkTileMovementBehavior, AttackBehavior
}