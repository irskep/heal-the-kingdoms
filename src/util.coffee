_ = require 'underscore'

# fuck you internet
window.requestAnimationFrame = (
  window.requestAnimationFrame ||
  window.mozRequestAnimationFrame ||
  window.webkitRequestAnimationFrame ||
  window.oRequestAnimationFrame);

_.choice = (options, weights = null, totalWeight = null) ->
  return null unless options?.length
  return options[_.random(0, options.length - 1)] unless weights

  total = totalWeight or _.sum(weights)
  r = Math.random() * total
  upto = 0
  for i in [0..weights.length]
     if upto + weights[i] > r
        return options[i]
     upto += weights[i]
  throw "Shouldn't get here"


module.exports = {}  # just require me to have shit work