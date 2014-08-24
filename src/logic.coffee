Bacon = require 'baconjs'
React = require 'react/addons'
_ = require 'underscore'
util = require './util'

{Vector2, Rect2} = require './geometry'
color = require './color'
keyboard = require './keyboard'
{TwoFrameSubject, TileSubject, TILE_SIZE, SRC_TILE_SIZE} = require './subject'
{ImageStore} = require './imageStore'
actor = require './actor'

{InventoryItem} = require './inventory'
{DrawableTileMap, LogicalTileMap, InventoryMap} = require './tileMap'



class Scene
  update: (t) -> throw "Not implemented"
  render: (ctx) -> throw "Not implemented"


class TitleScreen
  constructor: ->
  init: (@sceneManager) ->
    keyboard.downs(window.keyboardSettings.playerAction).take(1)
      .onValue ({event}) =>
        event.preventDefault()
        @sceneManager.setScene @sceneManager.scenes["0-preamble"]
  update: ->
  render: (ctx, canvasSize) ->
    ctx.save()
    ctx.fillStyle = color.black
    ctx.fillRect(0, 0, canvasSize.x, canvasSize.y);
    ctx.font = '64pt Niconne'
    ctx.textAlign = 'center'
    ctx.fillStyle = color.yellow
    ctx.fillText "Heal the Kingdoms", canvasSize.x / 2, canvasSize.y / 3

    ctx.font = '48pt Niconne'
    ctx.fillText("Press #{window.keyboardSettings.playerAction} to begin.",
      canvasSize.x / 2, canvasSize.y / 1.6)
    ctx.restore()


class Retry
  constructor: (@next, @text) ->
  init: (@sceneManager) ->
    keyboard.downs(window.keyboardSettings.playerAction).take(1)
      .onValue ({event}) =>
        event.preventDefault()
        @sceneManager.setScene @sceneManager.scenes[@next]
  update: ->
  render: (ctx, canvasSize) ->
    ctx.save()
    ctx.fillStyle = color.black
    ctx.fillRect(0, 0, canvasSize.x, canvasSize.y);
    ctx.font = '64pt Niconne'
    ctx.textAlign = 'center'
    ctx.fillStyle = color.yellow
    ctx.fillText @text, canvasSize.x / 2, canvasSize.y / 3

    ctx.font = '48pt Niconne'
    ctx.fillText("Press #{window.keyboardSettings.playerAction} to try again.",
      canvasSize.x / 2, canvasSize.y / 1.6)
    ctx.restore()


class Preamble
  constructor: ({@text, @nextScene}) ->
  init: (@sceneManager) ->
    keyboard.downs(window.keyboardSettings.playerAction).take(1).onValue =>
      @sceneManager.setScene @sceneManager.scenes[@nextScene]
  update: ->
  render: (ctx, canvasSize) ->
    ctx.save()
    ctx.fillStyle = color.black
    ctx.fillRect(0, 0, canvasSize.x, canvasSize.y);

    ctx.font = '24pt Niconne'
    ctx.textAlign = 'left'
    ctx.fillStyle = color.yellow
    ctx.fillText @text, 20, 30, canvasSize.x - 40

    ctx.fillText(
      "Press #{window.keyboardSettings.playerAction} to continue.",
      20, canvasSize.y - 10)
    ctx.restore()


class Level extends Scene
  constructor: ({@imageStore, @logicalData, @drawData, @scripts}) ->
    @drawableMap = new DrawableTileMap(
      @imageStore.images['tiles'], @drawData)
    @logicalMap = new LogicalTileMap(@logicalData)

    @textMap = do ->
      data = {
       0: {0: "YAY TEXT!"},
       3: {24: "Far across the land, blah blah blabbety blah."}
      }
      getText: (position) -> data[position.y]?[position.x]

    @teardowns = []

  init: (@sceneManager) ->
    @actors = []

    validPositions = []
    for y in [0...@logicalMap.size.y]
      for x in [0...@logicalMap.size.x]
        position = new Vector2(x, y)
        validPositions.push(position) if @logicalMap.getIsPath(position)

    @inventoryMap = new InventoryMap(
      @imageStore.images['DawnLike_3/Items/Boot'], validPositions,
      @logicalData)

    kill = (target) =>
      return if target.deathTime
      target.deathTime = Date.now()
      callback = =>
        if target == @player
          @scripts.onPlayerDeath?(target)
        else
          @scripts.onNPCDeath?(target)
      setTimeout(callback, 2000)

    @npcs = []
    npcSubject = new TwoFrameSubject(@imageStore, 'Player', 0, 500)
    @npcs.push new actor.Actor(npcSubject, [
      new actor.AttackBehavior({
        @logicalMap,
        tilePosition: _.choice(validPositions),
        getTarget: (=> @player),
        onHit: (=> kill(@player))
      })
    ])
    _.each @npcs, (npc) => @actors.push(npc)

    playerSubject = new TwoFrameSubject(@imageStore, 'Player', 1, 500)
    @player = new actor.Actor(playerSubject, [
      new actor.KeyboardControlledTileMovementBehavior(
        @logicalMap, @logicalMap.getPlayerStartingPosition()),
    ])
    @actors.push @player

    stabs = (
      keyboard.downs(window.keyboardSettings.playerStabLeft)
        .map(new Vector2(-1, 0))
    ).merge(
      keyboard.downs(window.keyboardSettings.playerStabRight)
        .map(new Vector2(1, 0))
    )
    @teardowns.push(stabs.onValue (stab) =>
      stabTargetPosition = @player.tilePosition.add(stab)
      stabTarget = _.find @npcs, (npc) =>
        (npc.tilePosition.isEqual(@player.tilePosition) or
          npc.tilePosition.isEqual(stabTargetPosition))
      if stabTarget
        kill(stabTarget)
    )

    @teardowns.push(keyboard.downs(window.keyboardSettings.playerAction)
      .onValue ({event}) =>
        event.preventDefault()
        item = @inventoryMap.getItem(@player.tilePosition)
        if item
          @inventoryMap.removeItem(@player.tilePosition)
          @sceneManager.getState().inventory.push(item)
          @sceneManager.notifyState()
    )

    @teardowns.push(@player.tilePositionUpdates.skipDuplicates(_.isEqual)
      .onValue (position) =>
        @sceneManager.getState().text = @textMap.getText(position)
        @sceneManager.notifyState()
    )
    @player.tilePositionUpdates.push(@player.tilePosition)

    @lastTime = Date.now()

  teardown: ->
    _.each @teardowns, (t) -> t()

  onMessage: (message) ->
    if (message.type == 'dropItem' and
        not @inventoryMap.getItem(@player.tilePosition))
      @inventoryMap.putItem(@player.tilePosition, message.item)
      @sceneManager.getState().inventory = _.without(
        @sceneManager.getState().inventory, message.item)
      @sceneManager.notifyState()

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
    @inventoryMap.render(ctx, Rect2.fromCenter(mapCenter, canvasSize))
    _.each @actors, (a) -> a.render(ctx)

    if keyboard.getIsKeyDown(window.keyboardSettings.playerStabLeft)
      ctx.fillStyle = 'red'
      ctx.beginPath()
      ctx.arc(
        @player.worldPosition.x - TILE_SIZE.x / 2,
        @player.worldPosition.y + TILE_SIZE.y / 2,
        TILE_SIZE.x / 4, 0, Math.PI * 2)
      ctx.fill()
    else if keyboard.getIsKeyDown(window.keyboardSettings.playerStabRight)
      ctx.fillStyle = 'red'
      ctx.beginPath()
      ctx.arc(
        @player.worldPosition.x + TILE_SIZE.x * 1.5,
        @player.worldPosition.y + TILE_SIZE.y / 2,
        TILE_SIZE.x / 4, 0, Math.PI * 2);
      ctx.fill()
    ctx.restore()


initImages = -> new ImageStore()


initInteractive = (imageStore) ->
  currentScene = null

  scenes = {
    "0-preamble": new Preamble({
      text: "
        You are about to begin the test level. Allow the dude to touch you."
      nextScene: "0-level"
    }),
    "0-level": new Level({
      imageStore,
      logicalData: require('./maps/test_logical'),
      drawData: require('./maps/test'),
      scripts: {
        onPlayerDeath: -> sceneManager.setScene(scenes['1-preamble'])
        onNPCDeath: (stabTarget) ->
          sceneManager.setScene(new Retry('0-level', "You killed him."))
      }}),
    "1-preamble": new Preamble({
      text: "
        You are about to begin level 1. Kill the dude by stabbing him with
        “#{window.keyboardSettings.playerStabLeft}” and
        “#{window.keyboardSettings.playerStabRight}”."
      nextScene: "1-level"
    }),
    "1-level": new Level({
      imageStore,
      logicalData: require('./maps/1_cave_logical'),
      drawData: require('./maps/1_cave'),
      scripts: {
        onPlayerDeath: ->
          sceneManager.setScene(new Retry('1-level', "You have died."))
        onNPCDeath: (stabTarget) -> sceneManager.setScene(new TitleScreen())
      }}),
  }

  state = {inventory: [], text: null}
  stateUpdates = new Bacon.Bus()

  sceneManager =
    scenes: scenes
    getState: -> state
    notifyState: -> stateUpdates.push(state)
    setScene: (newScene) ->
      currentScene?.teardown?()
      currentScene = newScene
      currentScene.init(sceneManager)
    sendMessage: (message) ->
      currentScene?.onMessage(message)

  #sceneManager.setScene(scenes['0-level'])
  sceneManager.setScene(new TitleScreen())

  run: (canvas) ->
    canvasSize = new Vector2(canvas.width, canvas.height)
    ctx = canvas.getContext('2d')
    _run = ->
      currentScene?.update()
      currentScene?.render(ctx, canvasSize)
      requestAnimationFrame(_run)
    requestAnimationFrame(_run)
  state: stateUpdates.toProperty(state)
  sceneManager: sceneManager


module.exports = {initImages, initInteractive}