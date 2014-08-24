# @cjsx React.DOM
_ = require 'underscore'
window.React = React = require 'react/addons'

state = require './state'
logic = require './logic'
model = require './model'
color = require './color'
{TILE_SIZE, SRC_TILE_SIZE} = require './subject'
{Vector2} = require './geometry'

window.keyboardSettings =
  playerLeft: 'a'
  playerRight: 'd'
  playerUp: 'w'
  playerDown: 's'

WIDTH = 768

$ ->
  React.renderComponent(
    <HTKRoot />,
    $('#htk-root').get(0))

HTKRoot = React.createClass
  displayName: 'HTKRoot'
  render: ->
    <div>
      <h1 style={{marginTop: 0}} className="title">
        Heal the Kingdoms
      </h1>
      <GameView />
      <p>
        Move with WASD. Switch levels with the number keys.
      </p>
    </div>

GameView = React.createClass
  displayName: 'GameView'
  getInitialState: -> {isLoaded: false}
  componentDidMount: ->
    imageStore = logic.initImages()
    @setState {imageStore}
    imageStore.isComplete.filter(_.identity).onValue =>
      {run, state, sceneManager} = logic.initInteractive(imageStore)
      @setState
        isLoaded: true
        runGame: run
        sceneManager: sceneManager
      state.onValue (newState) =>
        @setState {gameState: newState}
  render: ->
    if @state.isLoaded and @state.gameState
      <div>
        <WorldView runGame={@state.runGame} />
        <Inventory items={@state.gameState.inventory}
                   sceneManager={@state.sceneManager} />
      </div>
    else
      <span>"Still loading..."</span>

Inventory = React.createClass
  displayName: 'Inventory'
  render: ->
    <div style={{width: WIDTH}}>
      {_.map @props.items, (item) =>
        <InventoryItem item={item} style={{float: 'left'}}
        onClick={=> @props.sceneManager.sendMessage({type: 'dropItem', item})}
        />
      }
      <div style={{clear: 'both'}} />
    </div>

InventoryItem = React.createClass
  displayName: 'InventoryItem'
  render: ->
    scale = TILE_SIZE.pairDivide(SRC_TILE_SIZE);
    tileSubject = @props.item.tileSubject
    backgroundSize = new Vector2(
        tileSubject.sourceImage.width, tileSubject.sourceImage.height)
      .pairMultiply(scale)
    offset = tileSubject.sourceCoordinates
      .pairMultiply(SRC_TILE_SIZE)
      .pairMultiply(scale)
      .multiply(-1)

    @transferPropsTo <div className="pixel-art-sprite" style={{
        width: TILE_SIZE.x, height: TILE_SIZE.y, position: 'relative',
        overflow: 'hidden',
        backgroundImage: "url(#{tileSubject.sourceImage.src})",
        backgroundPosition: "#{offset.x}px #{offset.y}px",
        backgroundSize: "#{backgroundSize.x}px #{backgroundSize.y}px"
      }} />

WorldView = React.createClass
  displayName: 'WorldView'
  getDefaultProps: -> {width: WIDTH, height: 576}
  componentDidMount: -> @props.runGame(@getDOMNode())
  render: ->
    <canvas className="game-view"
        width={@props.width} height={@props.height}
        style={{
          width: @props.width, height: @props.height,
          backgroundColor: 'darkgreen'
        }}>
    </canvas>

module.exports = {}
