_ = require 'underscore'

{Vector2, Rect2} = require './geometry'
{TILE_SIZE, drawTile, SRC_TILE_SIZE, TileSubject} = require './subject'
{InventoryItem} = require './inventory'


class TileMap
  @worldCoordsToTileCoords: (worldPoint, floorOrCeil='floor') ->
    worldPoint.pairDivide(TILE_SIZE)[floorOrCeil]()
  @tileCoordsToWorldCoords: (tilePoint) ->
    tilePoint.pairMultiply(TILE_SIZE)

  constructor: (@mapData) ->
    @size = new Vector2(
      @mapData.layers[0][0].length, @mapData.layers[0].length)


class DrawableTileMap extends TileMap

  constructor: (@mapTileImage, args...) ->
    super(args...)
    imageColumns = @mapTileImage.width / SRC_TILE_SIZE.x
    @layers = _.map @mapData.layers, (layer) ->
      _.map layer, (row) ->
        _.map row, (index) ->
          return null unless index > 0
          index -= 1
          new Vector2(index % imageColumns, Math.floor(index / imageColumns))

  render: (ctx, worldRect) ->
    worldRectMin = TileMap.worldCoordsToTileCoords(worldRect.getMin(), 'floor')
    worldRectMax = TileMap.worldCoordsToTileCoords(worldRect.getMax(), 'ceil')
    startX = Math.max(0, worldRectMin.x)
    startY = Math.max(0, worldRectMin.y)
    endX = Math.min(@size.x, worldRectMax.x)
    endY = Math.min(@size.y, worldRectMax.y)

    for layer in [0...@layers.length]
      for y in [startY...endY]
        for x in [startX...endX]
          if @layers[layer][y][x]
            position = TILE_SIZE.pairMultiply({x, y})
            drawTile(@mapTileImage, @layers[layer][y][x], ctx, position)
    null


class LogicalTileMap extends TileMap

  constructor: (args...) ->
    super(args...)
    @data = @mapData.layers[0]

  getPlayerStartingPosition: ->
    for row in [0...@data.length]
      for col in [0...@data[row].length]
        if @data[row][col] == 1 then return new Vector2(col, row)
    throw "No player starting position found"

  getValue: (position) ->
    if @data[position.y]? and @data[position.y][position.x]?
      @data[position.y][position.x]
    else
      null
  getIsPath: (position) -> @getValue(position) == 1
  getIsDoor: (position) -> @getValue(position) == 3


class InventoryMap extends TileMap
  constructor: (@inventoryImage, validPositions, args...) ->
    super(args...)
    positions = _.first(_.shuffle(validPositions), 20)
    console.log 'boots at', positions
    @data = _.map @mapData.layers[0], (row, rowIndex) =>
      _.map row, (value, col) =>
        # TODO: read from actual map instead of ignoring value
        if _.find(positions, (pos) -> pos.x == col and pos.y == rowIndex)
          new InventoryItem(
            new TileSubject(@inventoryImage, _.random(10)), value, '?')
        else
          null

  render: (ctx, worldRect) ->
    worldRectMin = TileMap.worldCoordsToTileCoords(worldRect.getMin(), 'floor')
    worldRectMax = TileMap.worldCoordsToTileCoords(worldRect.getMax(), 'ceil')
    startX = Math.max(0, worldRectMin.x)
    startY = Math.max(0, worldRectMin.y)
    endX = Math.min(@size.x, worldRectMax.x)
    endY = Math.min(@size.y, worldRectMax.y)

    for y in [startY...endY]
      for x in [startX...endX]
        if @data[y][x]
          position = TILE_SIZE.pairMultiply({x, y})
          @data[y][x].tileSubject.render(ctx, position)
    null


module.exports = {TileMap, DrawableTileMap, LogicalTileMap, InventoryMap}