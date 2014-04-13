Config = require('../config')

tables = {}
playersCount = 0
structure = Config.getStructure()
intervalTime = Config.getIntervalTime()
state = 'waiting'
level = 0

join = (name, key, socketId) ->
  if !tables[0] || tables[0].players.length < 10
    if !tables[0]
      tables[0] = {}
    if !tables[0].players
      tables[0].players = []
    tables[0].players[tables[0].players.length] = {
      id: playersCount,
      name: name,
      key: key,
      socketId: socketId,
      isActive: false,
      win: null,
      tie: null,
      hand: []
    }
  playersCount += 1

gameStart = () ->
  level = 0
  stack = Config.getStack()
  for key, table of tables
    tables[key].players = [].concat(shufflePlayers(tables[key].players))
    tables[key].dealerButton = Math.floor(Math.random()*tables[key].players.length)
    tables[key].pot = 0
    # 初期スタックの設定
    for i in [0...tables[key].players.length]
      tables[key].players[i].stack = 10000
    # SB BB のチップ提出
    sbPosition = (tables[key].dealerButton+1)%tables[key].players.length
    bbPosition = (tables[key].dealerButton+2)%tables[key].players.length
    console.log 'sbPosition = '+sbPosition
    console.log 'bbPosition = '+bbPosition
    tables[key].pot += Number(structure[level]/2)
    tables[key].players[sbPosition].stack -= Number(structure[level]/2)
    console.log 'tables[key].players[sbPosition].stack = '+tables[key].players[sbPosition].stack
    console.log 'tables[key].players[bbPosition].stack = '+tables[key].players[bbPosition].stack
    tables[key].pot += structure[level]
    tables[key].players[bbPosition].stack -= structure[level]
    console.log 'tables[key].players[sbPosition].stack = '+tables[key].players[sbPosition].stack
    console.log 'tables[key].players[bbPosition].stack = '+tables[key].players[bbPosition].stack
    dealPlayersHands(key)
  setTimeout ->
    blindUp()
  , intervalTime
  state = 'gaming'

getInfo = () ->
  info = {
    state: state,
    level: level,
    tables: {}
  }
  for key, value of tables
    info.tables[key] = {
      pot: tables[key].pot,
      dealerButton: tables[key].dealerButton,
      players: tables[key].players
    }
  return info

getState = () ->
  return state

getTableInfo = (tableId) ->
  tableInfo = {
    state: state,
    level: level,
    pot: tables[tableId].pot,
    dealerButton: tables[tableId].dealerButton,
    players: []
  }
  for key, player of tables[tableId].players
    tableInfo.players[key] = {
      name: player.name,
      stack: player.stack,
      isActive: player.isActive
    }
  return tableInfo

module.exports = {
  join: join,
  getInfo: getInfo,
  gameStart: gameStart,
  getState: getState,
  getTableInfo: getTableInfo
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

shuffleArray = (targetArray) ->
  length = targetArray.length
  for key, value of targetArray
    j = Math.floor(Math.random()*length)
    t = value
    targetArray[j] = value
    targetArray[key] = t
  return targetArray

shufflePlayers = (players) ->
  length = players.length
  for key, value of players
    j = Math.floor(Math.random()*length)
    t = {}
    t = value
    players[j] = {}
    players[j] = value
    players[key] = {}
    players[key] = t
  return players
