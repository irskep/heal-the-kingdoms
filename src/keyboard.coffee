Bacon = require 'baconjs'
keyCodeToName = require './keyCodeToName'


keyboard = do ->
  pressedKeys = {}

  $document = $(document)

  downs = $document.asEventStream('keydown').map (e) ->
    {event: e, name: keyCodeToName[e.keyCode]}
  ups = $document.asEventStream('keyup').map (e) ->
    {event: e, name: keyCodeToName[e.keyCode]}

  downs.onValue ({name}) -> pressedKeys[name] = true
  ups.onValue ({name}) -> pressedKeys[name] = false

  getIsKeyDown: (k) -> !!pressedKeys[k]
  downs: (keys...) -> downs.filter ({name}) -> name in keys
  ups: (keys...) -> ups.filter ({name}) -> name in keys


module.exports = keyboard