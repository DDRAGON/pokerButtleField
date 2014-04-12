Config = require('../config')

tables = {}
playersCount = 0
structure = Config.getStructure()
intervalTime = Config.getIntervalTime()
state = 'waiting'
level = 0

join = (name, key) ->
  if !tables[0] || tables[0].players.length < 10
    if !tables[0]
      tables[0] = {}
    if !tables[0].players
      tables[0].players = []
    tables[0].players[playersCount] = {
      id: playersCount,
      name: name,
      key: key,
      isActive: false,
      win: null,
      tie: null,
      hand: []
    }
  playersCount += 1
  console.log 'join called!'

getInfo = () ->
  info = {
    state: state,
    level: level,
    tables: {}
  }
  for key, value of tables
    info.tables[key] = {
      players: tables[key].players
    }
  return info

gameStart = () ->
  state = 'gaming'
  level = 0
  for key, value of tables
    dealPlayersHands(key)
  setTimeout ->
    blindUp()
  , intervalTime



module.exports = {
  join: join,
  getInfo: getInfo,
  gameStart: gameStart
}

blindUp = () ->
  level += 1
  setTimeout ->
    blindUp()
  , intervalTime

dealPlayersHands = (tableId) ->
  tables[tableId].deck = [].concat(createDeck())
  for i in [0...2]
    for key, value of tables[tableId].players
      cardPosition = Math.floor(Math.random() * tables[tableId].deck.length);
      tables[tableId].players[key].hand[i] = tables[tableId].deck[cardPosition]
      tables[tableId].deck.splice(cardPosition, 1)
      tables[tableId].players[key].isActive = true
  console.log 'check it!'


createDeck = () ->
  trumps = [
    'As','2s','3s','4s','5s','6s','7s','8s','9s','Ts','Js','Qs','Ks',
    'Ah','2h','3h','4h','5h','6h','7h','8h','9h','Th','Jh','Qh','Kh',
    'Ad','2d','3d','4d','5d','6d','7d','8d','9d','Td','Jd','Qd','Kd',
    'Ac','2c','3c','4c','5c','6c','7c','8c','9c','Tc','Jc','Qc','Kc'
  ]
  return shuffleArray(trumps)

shuffleArray = (trumps) ->
  length = trumps.length
  for key, value of trumps
    j = Math.floor(Math.random()*length)
    t = value
    trumps[j] = value
    trumps[key] = t
  return trumps
