Bacon = require 'baconjs'
_ = require 'underscore'


getImageUrl = (identifier) -> "img/#{identifier}.png"


PRELOAD = [
  'Player0'
  'Player1'
  'tiles'
  'DawnLike_3/Items/Boot'
]


class ImageStore
  constructor: ->
    @images = {}
    @loadedCount = 0
    completes = new Bacon.Bus()
    @isComplete = completes.map(true).toProperty(false)

    _.each PRELOAD, (identifier) =>
      img = new Image()
      src = getImageUrl(identifier)
      @images[identifier] = img
      img.onload = =>
        @loadedCount += 1
        if @loadedCount == _.size @images
          completes.push()
      img.src = src


module.exports = {ImageStore, getImageUrl}