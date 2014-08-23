_ = require 'underscore'
{Vector2, Rect2} = require './geometry'


SRC_TILE_SIZE = new Vector2(16, 16)
TILE_SIZE = SRC_TILE_SIZE.multiply(2)
#TILE_SIZE = SRC_TILE_SIZE


class TileType
  constructor: (@sourceImage, @sourceCoordinates) ->
  render: (ctx, position) ->
    ctx.imageSmoothingEnabled = false
    ctx.drawImage(
      @sourceImage,
      @sourceCoordinates.x * SRC_TILE_SIZE.x,
      @sourceCoordinates.y * SRC_TILE_SIZE.y,
      SRC_TILE_SIZE.x, SRC_TILE_SIZE.y,
      position.x, position.y,
      TILE_SIZE.x, TILE_SIZE.y)



PRELOAD = [
  'Objects/Floor'
  'Characters/Player0'
  'Characters/Player1'
]

getImageUrl = (identifier) -> "img/DawnLike_3/#{identifier}.png"


class ImageStore
  constructor: (@loadedCallback) ->
    @images = {}
    @loadedCount = 0

    for identifier in PRELOAD
      img = new Image()
      src = getImageUrl(identifier)
      @images[src] = img
      img.onload = =>
        @loadedCount += 1
        if @loadedCount == _.size @images
          @loadedCallback()
      img.src = src


class TileTypeStore
  constructor: (@imageStore) ->
    @tileTypes = {
      test1: new TileType(
        @imageStore.images[getImageUrl('Objects/Floor')], new Vector2(1, 4)),
    }


class CharacterType
  constructor: (
      @imageStore, @imageName, @sourceCoordinates, @animationPeriod) ->
    @animationOffset = _.random(@animationPeriod - 1)
    @frameTileTypes = [
      new TileType(
        @imageStore.images[getImageUrl(@imageName + '0')], @sourceCoordinates),
      new TileType(
        @imageStore.images[getImageUrl(@imageName + '1')], @sourceCoordinates),
    ]

  render: (ctx, position) ->
    i = Math.floor((Date.now() + @animationOffset) / @animationPeriod)
    @frameTileTypes[i % @frameTileTypes.length].render(ctx, position)


module.exports = {
  TileType, ImageStore, TileTypeStore, TILE_SIZE, CharacterType}