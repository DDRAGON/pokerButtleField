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
  for tableId, table of tables
    table.players = [].concat(shufflePlayers(table.players))
    table.dealerButton = Math.floor(Math.random()*table.players.length)
    # ゲームの初期設定
    table.playedHandCount = 0
    table.actionCount = 0
    table.lastBet = 0
    table.pot = 0
    # 初期スタックの設定
    for i in [0...table.players.length]
      table.players[i].stack = 10000
    # SB BB のチップ提出
    sbPosition = (table.dealerButton+1)%table.players.length
    bbPosition = (table.dealerButton+2)%table.players.length
    table.pot += Number(structure[level]/2)
    table.players[sbPosition].stack -= Number(structure[level]/2)
    table.pot += structure[level]
    table.players[bbPosition].stack -= structure[level]
    # 手札を配る
    dealPlayersHands(tableId)
    # 手番プレイヤーの設定
    table.actionPlayerSeat = (table.dealerButton+3)%table.players.length

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
      lastBet: tables[key].lastBet,
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

getActionPlayer = (tableId) ->
  return tables[tableId].players[tables[tableId].actionPlayerSeat]

action = (data, callback) ->
  key = data.key
  action = data.action
  amount = data.amount
  tableId = 0
  if key == tables[tableId].players[tables[tableId].actionPlayerSeat].key
    actionPlayerSeat = tables[tableId].actionPlayerSeat
    switch action
      when 'fold'
        tables[tableId].players[actionPlayerSeat].isActive = false
        callback({status: 'ok', message: 'got fold.'})
      when 'call'
        tables[tableId].pot += tables[tableId].lastBet
        tables[tableId].players[actionPlayerSeat].stack -= tables[tableId].lastBet
        callback({status: 'ok', message: 'got call.'})
      when 'raise'
        if amount < tables[tableId].lastBet*2
          amount = tables[tableId].lastBet*2
        tables[tableId].pot += amount
        tables[tableId].players[actionPlayerSeat].stack -= amount
        callback({status: 'ok', message: 'got raise '+amount})
    tables[tableId].actionPlayerSeat += 1
  else
    callback('ignroe')


module.exports = {
  join: join,
  getInfo: getInfo,
  gameStart: gameStart,
  getState: getState,
  getTableInfo: getTableInfo,
  getActionPlayer: getActionPlayer,
  action: action
}

# ここから下はエクスポートしないプライベートメソッド
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
    t = ''
    t = value
    targetArray[j] = ''
    targetArray[j] = value
    targetArray[key] = ''
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
