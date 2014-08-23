_ = require 'underscore'

# fuck you internet
window.requestAnimationFrame = window.requestAnimationFrame || window.mozRequestAnimationFrame ||
                          window.webkitRequestAnimationFrame || window.oRequestAnimationFrame;


class Vector2
  constructor: (@x, @y) ->
    throw "NaN" if isNaN(@x) or isNaN(@y)
  pairMultiply: (other) -> new Vector2(@x * other.x, @y * other.y)
  pairDivide: (other) -> new Vector2(@x / other.x, @y / other.y)


class Rect2
  constructor: (@xmin, @ymin, @xmax, @ymax) ->
    throw "NaN" if isNaN(@xmin) or isNaN(@ymin) or isNaN(@xmax) or isNaN(@ymax)
  getMin: -> new Vector2(@xmin, @ymin)
  getMax: -> new Vector2(@xmax, @ymax)


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


class TileMap
  @worldPointToTileCoordinates: (worldPoint) ->
    worldPoint.pairDivide(TILE_SIZE)
  constructor: (@size, @getTile) ->
  render: (ctx, worldRect) ->
    worldRectMin = TileMap.worldPointToTileCoordinates(worldRect.getMin())
    worldRectMax = TileMap.worldPointToTileCoordinates(worldRect.getMax())
    startX = Math.max(0, worldRectMin.x)
    startY = Math.max(0, worldRectMin.y)
    endX = Math.min(@size.x, worldRectMax.x)
    endY = Math.min(@size.y, worldRectMax.y)
    console.log startX, 'to', endX
    console.log startY, 'to', endY
    for y in [startY..endY]
      for x in [startX..endX]
        @getTile(x, y).render(ctx, TILE_SIZE.pairMultiply({x, y}))
    null


init = (canvas) ->
  imageStore = new ImageStore ->
    tileTypeStore = new TileTypeStore(imageStore)
    map = new TileMap new Vector2(20, 20), (x, y) ->
      # TODO: map reading logic
      return tileTypeStore.tileTypes.test1

    ctx = canvas.getContext('2d')
    requestId = requestAnimationFrame ->
      map.render(ctx, new Rect2(0, 0, canvas.width, canvas.height))


module.exports = {init}