_ = require 'underscore'

getItem = (k, decode = false) ->
  d = localStorage.getItem(k)
  switch
    when !d or d == 'undefined' or d == 'null'
      null
    when decode
      try
        JSON.parse(d)
      catch SyntaxError
        null
    else
      d

setItem = (k, v) ->
  if _.isString(v)
    localStorage.setItem(k, v)
  else
    localStorage.setItem(k, JSON.stringify(v))
  trigger('k:' + k, v)

module.exports = {getItem, setItem}