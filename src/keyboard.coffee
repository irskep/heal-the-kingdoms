Bacon = require 'baconjs'
keyCodeToName = require './keyCodeToName'


keyboard = do ->
  pressedKeys = {}

  $document = $(document)

  downs = $document.asEventStream('keydown').map (e) ->
    keyCodeToName[e.keyCode]
  ups = $document.asEventStream('keyup').map (e) ->
    keyCodeToName[e.keyCode]

  downs.onValue (k) -> pressedKeys[k] = true
  ups.onValue (k) -> pressedKeys[k] = false

  getIsKeyDown: (k) -> !!pressedKeys[k]
  downs: (keys...) -> downs.filter (k) -> k in keys
  ups: (keys...) -> ups.filter (k) -> k in keys


module.exports = keyboard