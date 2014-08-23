colorScss = require('./_dawnbringer.scss');

color = {}

for line in colorScss.match(/[^\r\n]+/g)
  lineRegex = /\$(.*): (.*);/g
  match = lineRegex.exec(line)
  if match
    color[match[1]] = match[2]

module.exports = color