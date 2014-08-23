# @cjsx React.DOM
_ = require 'underscore'
window.React = React = require 'react/addons'

state = require './state'
logic = require './logic'
model = require './model'
color = require './color'

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
  getDefaultProps: -> {width: 768, height: 576}
  componentDidMount: -> @stop = logic.init(this.getDOMNode())
  componentWillUnmount: -> @stop
  render: ->
    <canvas className="game-view"
        width={@props.width} height={@props.height}
        style={{
          width: @props.width, height: @props.height,
          backgroundColor: 'darkgreen'
        }}>
    </canvas>

module.exports = {}
