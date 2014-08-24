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


class TileSubject
  constructor: (@sourceImage, @sourceCoordinates) ->
  render: (ctx, position) ->
    drawTile(@sourceImage, @sourceCoordinates, ctx, position)


class TwoFrameSubject
  constructor: (
      @imageStore, @imageName, @sourceCoordinates, @animationPeriod) ->
    @animationOffset = _.random(@animationPeriod - 1)
    @frameTileSubjects = [
      new TileSubject(
        @imageStore.images[@imageName + '0'], @sourceCoordinates),
      new TileSubject(
        @imageStore.images[@imageName + '1'], @sourceCoordinates),
    ]

  render: (ctx, position) ->
    i = Math.floor((Date.now() + @animationOffset) / @animationPeriod)
    @frameTileSubjects[i % @frameTileSubjects.length].render(ctx, position)


module.exports = {
  TileSubject, TILE_SIZE, TwoFrameSubject, drawTile, SRC_TILE_SIZE
}