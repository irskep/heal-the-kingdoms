# @cjsx React.DOM
_ = require 'underscore'
window.React = React = require 'react/addons'

state = require './state'
model = require './model'

console.log require './color'

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
    </div>

module.exports = {}
