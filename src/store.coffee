Bacon = require 'baconjs'
_ = require 'underscore'
{Vector2, Rect2} = require './geometry'


SRC_TILE_SIZE = new Vector2(16, 16)
TILE_SIZE = SRC_TILE_SIZE.multiply(2)
#TILE_SIZE = SRC_TILE_SIZE


drawTile = (sourceImage, sourceCoordinates, ctx, position) ->
  ctx.imageSmoothingEnabled = false
  ctx.drawImage(
    sourceImage,
    sourceCoordinates.x * SRC_TILE_SIZE.x,
    sourceCoordinates.y * SRC_TILE_SIZE.y,
    SRC_TILE_SIZE.x, SRC_TILE_SIZE.y,
    position.x, position.y,
    TILE_SIZE.x, TILE_SIZE.y)


class TileType
  constructor: (@sourceImage, @sourceCoordinates) ->
  render: (ctx, position) ->
    drawTile(@sourceImage, @sourceCoordinates, ctx, position)


PRELOAD = [
  'Player0'
  'Player1'
  'tiles'
]

getImageUrl = (identifier) -> "img/#{identifier}.png"


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


class TwoFrameSubject
  constructor: (
      @imageStore, @imageName, @sourceCoordinates, @animationPeriod) ->
    @animationOffset = _.random(@animationPeriod - 1)
    @frameTileTypes = [
      new TileType(
        @imageStore.images[@imageName + '0'], @sourceCoordinates),
      new TileType(
        @imageStore.images[@imageName + '1'], @sourceCoordinates),
    ]

  render: (ctx, position) ->
    i = Math.floor((Date.now() + @animationOffset) / @animationPeriod)
    @frameTileTypes[i % @frameTileTypes.length].render(ctx, position)


module.exports = {
  TileType, ImageStore, TILE_SIZE, TwoFrameSubject, drawTile, getImageUrl,
  SRC_TILE_SIZE
}