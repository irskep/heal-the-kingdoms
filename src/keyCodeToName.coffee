_ = require 'underscore'

module.exports = _.extend({}, [
  # General Keys (IE, MZ, Opera)
  _.object([x, String.fromCharCode(x).toLowerCase()] for x in [65..90]),
  {32: 'space', 13: 'enter', 9: 'tab', 27: 'esc', 8: 'backspace'},

  # Modifier Keys (IE, MZ, Opera)
  {16: 'shift', 17: 'control', 18: 'alt', 20: 'capslock', 144: 'numlock'},

  # Number Keys (IE, MZ, Opera)
  {
    49: '1', 50: '2', 51: '3', 52: '4', 53: '5', 54: '6', 55: '7', 56: '8',
    57: '9', 48: '0'
  },

  # Symbol Keys (No Opera due to collisions)
  {
    # IE (these appear not to collide with MZ or Opera)
    186: ';', 187: '=', 189: '-',

    # MZ (these appear not to collide with IE or Opera)
    59: ';', 61: '=', 109: '-',

    # IE, MZ
    188: ',', 190: '.', 191: '/', 192: '`', 219: '[', 220: '\\', 221: ']',
    222: '\''
  },

  # Arrow Keys (IE, MZ, Opera)
  {37: 'left', 38: 'up', 39: 'right', 40: 'down'},

  # Special Keys (IE, MZ, Opera)
  {
    45: 'insert', 46: 'delete', 36: 'home', 35: 'end', 33: 'pageup',
    34: 'pagedown'
  },

  # Function Keys (IE, MZ, Opera)
  _.object([x + 111, "F#{x}"] for x in [1..19]),

  # Keypad Keys (IE, MZ) (No Opera due to collisions) (assumes numlock is off)
  {
    110: '.', 96: 'num0', 97: 'num1', 98: 'num2', 99: 'num3', 100: 'num4',
    101: 'num5', 102: 'num6', 103: 'num7', 104: 'num8', 105: 'num9',
    107: 'num+', 109: 'num-', 106: 'num*', 111: 'num/'
  },

  # Branded Keys (IE, MZ) (No Opera due to collisions)
  # Combined windows 'start' and mac 'command' keys rather than having synonyms
  {
    # IE, MZ
    91: 'start_or_command',
    92: 'start_or_command', # refers to windows right-side 'start' key
    93: 'menu', # windows 'menu' key. collides with mac rightside 'command' key

    # MZ
    224: 'start_or_command'
  }
]...)