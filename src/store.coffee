_ = require 'underscore'
{Vector2, Rect2} = require './geometry'


TILE_SIZE = new Vector2(16, 16)


class TileType
  constructor: (@sourceImage, @sourceCoordinates) ->
  render: (ctx, position) ->
    ctx.drawImage(
      @sourceImage,
      @sourceCoordinates.x * TILE_SIZE.x,
      @sourceCoordinates.y * TILE_SIZE.y,
      TILE_SIZE.x, TILE_SIZE.y,
      position.x, position.y,
      TILE_SIZE.x, TILE_SIZE.y)



DAWNLIKE_URLS = [
  'Objects/Floor.png'
]


class ImageStore
  constructor: (@loadedCallback) ->
    @images = {}
    @loadedCount = 0

    for dawnlikeUrl in DAWNLIKE_URLS
      img = new Image()
      src = 'img/DawnLike_3/' + dawnlikeUrl
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
        @imageStore.images['img/DawnLike_3/Objects/Floor.png'],
        new Vector2(1, 4)),
      test2: new TileType(
        @imageStore.images['img/DawnLike_3/Objects/Floor.png'],
        new Vector2(1, 7)),
    }


module.exports = {TileType, ImageStore, TileTypeStore, TILE_SIZE}