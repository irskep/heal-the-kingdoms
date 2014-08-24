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
    </div>

GameView = React.createClass
  displayName: 'GameView'
  getInitialState: -> {isLoaded: false}
  componentDidMount: ->
    imageStore = logic.initImages()
    @setState {imageStore}
    imageStore.isComplete.filter(_.identity).onValue =>
      @setState {isLoaded: true}
  render: ->
    <div>
      {!@state.isLoaded and "Still loading..."}
      {@state.isLoaded && <WorldView imageStore={@state.imageStore} />}
    </div>

WorldView = React.createClass
  displayName: 'WorldView'
  getDefaultProps: -> {width: 768, height: 576}
  componentDidMount: ->
    logic.initInteractive(@getDOMNode(), @props.imageStore)
  render: ->
    <canvas className="game-view"
        width={@props.width} height={@props.height}
        style={{
          width: @props.width, height: @props.height,
          backgroundColor: 'darkgreen'
        }}>
    </canvas>

module.exports = {}
