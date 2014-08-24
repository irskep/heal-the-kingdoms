_ = require 'underscore'
util = require './util'

{Vector2, Rect2} = require './geometry'
color = require './color'
keyboard = require './keyboard'
{ImageStore, TwoFrameSubject} = require './store'
{
  Actor, KeyboardControlledTileMovementBehavior, RandomWalkTileMovementBehavior
} = require './actor'

{DrawableTileMap, LogicalTileMap} = require './tileMap'


class Scene
  update: (t) -> throw "Not implemented"
  render: (ctx) -> throw "Not implemented"


class Level extends Scene
  constructor: (@imageStore, @logicalData, @drawData, @scripts) ->
    @drawableMap = new DrawableTileMap(
      @imageStore.images['tiles'], @drawData)
    @logicalMap = new LogicalTileMap(@logicalData)

  init: (@sceneManager) ->
    @actors = []

    validPositions = []
    for y in [0...@logicalMap.size.y]
      for x in [0...@logicalMap.size.x]
        position = new Vector2(x, y)
        validPositions.push(position) if @logicalMap.getIsPath(position)

    npcSubject = new TwoFrameSubject(
      @imageStore, 'Player', new Vector2(0, 0), 500)
    @actors.push new Actor(npcSubject, [
      new RandomWalkTileMovementBehavior(
        @logicalMap, _.choice(validPositions)),
    ])

    playerSubject = new TwoFrameSubject(
      @imageStore, 'Player', new Vector2(1, 0), 500)
    @player = new Actor(playerSubject, [
      new KeyboardControlledTileMovementBehavior(
        @logicalMap, @logicalMap.getPlayerStartingPosition()),
    ])
    @actors.push @player

    @lastTime = Date.now()

  update: ->
    dt = (Date.now() - @lastTime) / 1000
    @lastTime = Date.now()
    _.each @actors, (a) -> a.update(dt)

  render: (ctx, canvasSize) ->
    ctx.save()
    ctx.fillStyle = color.black
    ctx.fillRect(0, 0, canvasSize.x, canvasSize.y);
    mapCenter = @player.getCenter().floor()

    ctx.translate(
      -mapCenter.x + canvasSize.x / 2,
      -mapCenter.y + canvasSize.y / 2)

    @drawableMap.render(ctx, Rect2.fromCenter(mapCenter, canvasSize))
    _.each @actors, (a) -> a.render(ctx)
    ctx.restore()


initImages = -> new ImageStore()


initInteractive = (canvas, imageStore) ->
  canvasSize = new Vector2(canvas.width, canvas.height)
  ctx = canvas.getContext('2d')

  currentScene = null

  scenes = {
    "1": new Level(
      imageStore, require('./maps/1_cave_logical'), require('./maps/1_cave'),
      {}),
    "0": new Level(
      imageStore, require('./maps/test_logical'), require('./maps/test'), {}),
  }

  sceneManager =
    scenes: scenes
    setScene: (newScene) ->
      currentScene?.teardown?()
      currentScene = newScene
      currentScene.init(sceneManager)

  sceneManager.setScene(scenes["1"])

  _.each scenes, (scene, key) ->
    keyboard.downs(key).onValue -> sceneManager.setScene(scene)

  run = ->
    currentScene?.update()
    currentScene?.render(ctx, canvasSize)
    requestAnimationFrame(run)
  requestAnimationFrame(run)


module.exports = {initImages, initInteractive}