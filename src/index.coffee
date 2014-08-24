# @cjsx React.DOM
_ = require 'underscore'
window.React = React = require 'react/addons'

state = require './state'
logic = require './logic'
model = require './model'
color = require './color'

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
      {run, state} = logic.initInteractive(imageStore)
      @setState
        isLoaded: true
        runGame: run
      state.onValue (newState) =>
        @setState {gameState: newState}
  render: ->
    if @state.isLoaded and @state.gameState
      <div>
        <WorldView runGame={@state.runGame} />
        <Inventory items={@state.gameState.inventory} />
      </div>
    else
      <span>"Still loading..."</span>

Inventory = React.createClass
  displayName: 'Inventory'
  render: ->
    <div style={{width: WIDTH}}>
      {_.map @props.items, (item) =>
        item.getComponent()
      }
    </div>

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
