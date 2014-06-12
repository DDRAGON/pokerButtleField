
config =
  viewTestingFlag: false,
  canvasWidth: 1000,
  canvasHeight: 650,
  cardWidth: 48,
  cardHeight: 64,
  tableWidth: 750,
  tableHeight: 500,
  chipWidth: 32,
  chipHeight: 32,
  dealerButtonWidth: 25,
  dealerButtonHeight: 25,
  bettingChipFontSize: 15,
  chipAndChipMargin: 5,
  nameFontSize: 20,
  activeFrameBold: 4,
  state:  'loading',
  mouseListener: false,
  clockTime: false,
  chipList: [1000, 500, 100, 50, 10, 5, 2, 1]

config.nameBoxWidth  = config.cardWidth*3
config.nameBoxHeight = Math.round(config.cardHeight*3/2)
config.tableX = Math.round(config.nameBoxWidth/2)
config.tableY = Math.round(config.nameBoxHeight/2)

imageName =
  [
    'Tranp.png', 'bg1.png', 'chip1.png', 'chip2.png', 'chip5.png', 'chip10.png', 'chip50.png', 'chip100.png',
    'chip500.png', 'chip1000.png', 'dealerButton.png'
  ]
images = {}


#Socket関連とゲーム関連
prepareForGames = () ->
  socket = io.connect 'http://'+host+':'+port+'/spectator'

  socket.on 'spectatorData', (data) ->
    config.state = 'drawing'
    drawSpectatorData(data)

  #ロードします
  checkLoad = () ->
    loadedCount += 1
    if loadedCount == imageName.length
      loaded()
  loadedCount = 0
  for i in [0...imageName.length]
    image = document.createElement "img"
    image.src = "/images/" + imageName[i]
    image.onload = -> checkLoad()
    images[imageName[i]] = image

  loaded = () ->
    config.state = "ready"

drawSpectatorData = (data) ->
  if config.viewTestingFlag == true
    data = dummyTableInfo(10, ['As','Jd','2h','5h','3c'])
  config.ctx.clearRect(0, 0, config.canvasWidth, config.canvasHeight)
  config.ctx.drawImage(images['bg1.png'], config.tableX, config.tableY)
  if !data.players
    return
  playersXY = getPlayersXYByNum(data.players.length)
  for playerId, player of data.players
    drawHands(player, playersXY[playerId].handsX, playersXY[playerId].handsY) # 手札の描画
    drawNameBox(player, playersXY[playerId].nameX, playersXY[playerId].nameY, data.actionPlayerSeat) # 名前空間の描画
    drawBoard(data.board) # ボードの描画
    drawBettingChips(player.lastBet, playersXY[playerId].chipX, playersXY[playerId].chipY) # チップの描画
    if config.viewTestingFlag == true || Number(playerId) == Number(data.dealerButton)
      config.ctx.drawImage(images['dealerButton.png'], playersXY[playerId].dealerButtonX,playersXY[playerId].dealerButtonY, config.dealerButtonWidth,config.dealerButtonHeight)

  if data.state == 'end'
    drawEndResult(data.players);


# ムービー関連
movieCounter = 0
loadingMovie = () ->
  if config.state == 'loading'
    setTimeout (-> loadingMovie()), 50
    config.ctx.clearRect(0, 0, config.canvasWidth, config.canvasHeight)
    config.ctx.fillStyle = "silver"
    config.ctx.font = "26px \'Times New Roman\'"
    loadingText = 'Loading'
    for i in [0..movieCounter]
      loadingText += '.'
    config.ctx.fillText(loadingText, 100, 300)
    movieCounter++
    if movieCounter > 5
      movieCounter = 0


createCanvas = () ->
  page = "<canvas id='canvas' width='" + config.canvasWidth + "' height='" + config.canvasHeight + "'> </canvas>"
  $('#tableDiv').html(page)
  
  canvas  = $('#canvas').get(0)
  canvas.width   = config.canvasWidth
  canvas.height  = config.canvasHeight
  config.ctx   = canvas.getContext("2d")
  loadingMovie()

$(document).ready ->
  createCanvas()
  prepareForGames()


#見なくていい private 関数たち
drawHands = (player, drawX, drawY) ->
  if !player.hand || !player.hand[0] || !player.hand[1]
    return
  drawcard(cardToCardNum(player.hand[0]),drawX,drawY)
  drawX += config.cardWidth
  drawcard(cardToCardNum(player.hand[1]),drawX,drawY)

drawNameBox = (player, nameX, nameY, actionPlayerSeat) ->
  setColorAndFont('black', 11)
  config.ctx.fillRect(nameX, nameY, config.nameBoxWidth, config.nameBoxHeight)
  if config.viewTestingFlag == true || Number(actionPlayerSeat) == Number(player.id)
    setColorAndFont('blue', 0)
    config.ctx.fillRect(nameX, nameY+config.nameBoxHeight-config.activeFrameBold, config.nameBoxWidth, config.activeFrameBold)
    config.ctx.fillRect(nameX, nameY, config.nameBoxWidth, config.activeFrameBold)
    config.ctx.fillRect(nameX, nameY, config.activeFrameBold, config.nameBoxHeight)
    config.ctx.fillRect(nameX+config.nameBoxWidth-config.activeFrameBold, nameY, config.activeFrameBold, config.nameBoxHeight)
  setColorAndFont('white', config.nameFontSize)
  config.ctx.fillText(player.name, nameX+config.activeFrameBold+1, nameY+config.nameFontSize+1)
  if player.stack
    config.ctx.fillText(player.stack, nameX+config.activeFrameBold+1, nameY+(config.nameFontSize+1)*2)
  if player.lastAction
    config.ctx.fillText(player.lastAction, nameX+config.activeFrameBold+1, nameY+(config.nameFontSize+1)*3)

drawEndResult = (players) ->
  for player in players
    setColorAndFont('black', config.nameFontSize)
    drawX = config.tableX + Math.floor(config.tableWidth/2)  - Math.floor(config.cardWidth*5/2) + 50
    drawY = config.tableY + Math.floor(config.tableHeight/2) - 1
    config.ctx.fillText(player.name + ' won the Game!', drawX, drawY)

drawBettingChips = (chipAmount, x, y) ->
  if !chipAmount ||  chipAmount< 1
    return
  chips = []
  # ベット額の描画
  setColorAndFont('black', config.bettingChipFontSize)
  config.ctx.fillText(chipAmount, x, y+config.chipHeight+config.bettingChipFontSize-1)
  # 描画するチップと枚数の計算
  for chip in config.chipList
    chipMany = Math.floor(chipAmount/chip)
    for i in [0...chipMany]
      chips.push(chip)
    chipAmount -= chipMany*chip
  drawedCount = 0
  # チップごとに描画位置を計算し描画する。
  for i in [(chips.length-1)..0]
    chip = chips[i]
    drawX = x
    drawY = y - Math.floor(drawedCount/2)*config.chipAndChipMargin
    if i%2 == 0
      drawX += config.chipWidth
    config.ctx.drawImage(images['chip'+chip+'.png'], drawX,drawY, config.chipWidth,config.chipHeight)
    drawedCount += 1

drawcard = (cardnum,x,y) ->
  cardmany = 10
  cutx = (cardnum %cardmany)*config.cardWidth;
  cuty = ((cardnum/cardmany) | 0)*config.cardHeight;
  config.ctx.drawImage(images["Tranp.png"],cutx,cuty,config.cardWidth,config.cardHeight,x,y,config.cardWidth,config.cardHeight)

drawBoard = (board) ->
  if !board
    return
  drawX = config.tableX + Math.floor(config.tableWidth/2)  - Math.floor(config.cardWidth*5/2)
  drawY = config.tableY + Math.floor(config.tableHeight/2)
  for boardCard in board
    cardNum = cardToCardNum(boardCard)
    drawcard(cardNum, drawX, drawY)
    drawX += config.cardWidth

getPlayersXYByNum = (playersNum) ->
  PlayersXY = []
  # 中心座標
  PlayersXY[0] = {x:(config.tableWidth*0/5), y:Math.round(config.tableHeight*2/4)}
  PlayersXY[1] = {x:(config.tableWidth*1/5), y:Math.round(config.tableHeight*1/4)}
  PlayersXY[2] = {x:(config.tableWidth*2/5), y:Math.round(config.tableHeight*0/4)}
  PlayersXY[3] = {x:(config.tableWidth*3/5), y:Math.round(config.tableHeight*0/4)}
  PlayersXY[4] = {x:(config.tableWidth*4/5), y:Math.round(config.tableHeight*1/4)}
  PlayersXY[5] = {x:(config.tableWidth*5/5), y:Math.round(config.tableHeight*2/4)}
  PlayersXY[6] = {x:(config.tableWidth*4/5), y:Math.round(config.tableHeight*3/4)}
  PlayersXY[7] = {x:(config.tableWidth*3/5), y:Math.round(config.tableHeight*4/4)}
  PlayersXY[8] = {x:(config.tableWidth*2/5), y:Math.round(config.tableHeight*4/4)}
  PlayersXY[9] = {x:(config.tableWidth*1/5), y:Math.round(config.tableHeight*3/4)}
  # 微調整と手札座標と名前ボックス座標
  PlayersXY[1].x -= config.chipWidth
  PlayersXY[1].y -= config.chipHeight
  PlayersXY[4].x += config.chipWidth
  PlayersXY[4].y -= config.chipHeight
  PlayersXY[6].x += config.chipWidth
  PlayersXY[6].y += config.chipHeight
  PlayersXY[9].x -= config.chipWidth
  PlayersXY[9].y += config.chipHeight
  for i in [0...playersNum]
    PlayersXY[i].x += config.tableX
    PlayersXY[i].y += config.tableY
    PlayersXY[i].handsX = PlayersXY[i].x - config.cardWidth
    PlayersXY[i].handsY = PlayersXY[i].y - Math.round(config.nameBoxHeight/2)
    PlayersXY[i].nameX  = PlayersXY[i].x - Math.round(config.nameBoxWidth/2)
    PlayersXY[i].nameY  = PlayersXY[i].y + Math.round(config.cardHeight/4)
  # チップ座標
  PlayersXY[0].chipX = PlayersXY[0].x +  Math.round(config.nameBoxWidth/2)
  PlayersXY[0].chipY = PlayersXY[0].y +  Math.round(config.cardHeight/4)
  PlayersXY[1].chipX = PlayersXY[1].x +  Math.round(config.nameBoxWidth/2)
  PlayersXY[1].chipY = PlayersXY[1].y +  Math.round(config.cardHeight/4)+config.nameBoxHeight-config.chipHeight
  PlayersXY[2].chipX = PlayersXY[2].x -  config.chipWidth
  PlayersXY[2].chipY = PlayersXY[2].y +  Math.round(config.cardHeight/4)+config.nameBoxHeight
  PlayersXY[3].chipX = PlayersXY[3].x -  config.chipWidth
  PlayersXY[3].chipY = PlayersXY[3].y +  Math.round(config.cardHeight/4)+config.nameBoxHeight
  PlayersXY[4].chipX = PlayersXY[4].x -  (Math.round(config.nameBoxWidth/2)+config.chipWidth*2)
  PlayersXY[4].chipY = PlayersXY[4].y +  Math.round(config.cardHeight/4)+config.nameBoxHeight-config.chipHeight
  PlayersXY[5].chipX = PlayersXY[5].x -  (Math.round(config.nameBoxWidth/2)+config.chipWidth*2)
  PlayersXY[5].chipY = PlayersXY[5].y +  Math.round(config.cardHeight/4)
  PlayersXY[6].chipX = PlayersXY[6].x -  (config.cardWidth+config.chipWidth*2)
  PlayersXY[6].chipY = PlayersXY[6].y +  (Math.round(config.cardHeight/4)-config.chipHeight-config.bettingChipFontSize)
  PlayersXY[7].chipX = PlayersXY[7].x -  config.chipWidth
  PlayersXY[7].chipY = PlayersXY[7].y +  Math.round(config.cardHeight/4)-config.cardHeight-config.chipHeight-config.bettingChipFontSize
  PlayersXY[8].chipX = PlayersXY[8].x -  config.chipWidth
  PlayersXY[8].chipY = PlayersXY[8].y +  Math.round(config.cardHeight/4)-config.cardHeight-config.chipHeight-config.bettingChipFontSize
  PlayersXY[9].chipX = PlayersXY[9].x +  config.cardWidth
  PlayersXY[9].chipY = PlayersXY[9].y +  (Math.round(config.cardHeight/4)-config.chipHeight-config.bettingChipFontSize)
  # ディーラーボタン座標
  PlayersXY[0].dealerButtonX = PlayersXY[0].chipX+config.chipWidth*2
  PlayersXY[0].dealerButtonY = PlayersXY[0].chipY+config.chipHeight
  PlayersXY[1].dealerButtonX = PlayersXY[1].chipX
  PlayersXY[1].dealerButtonY = PlayersXY[1].chipY+config.chipHeight+config.bettingChipFontSize
  PlayersXY[2].dealerButtonX = PlayersXY[2].chipX+Math.round(config.chipWidth/2)
  PlayersXY[2].dealerButtonY = PlayersXY[2].chipY+config.chipHeight+config.bettingChipFontSize
  PlayersXY[3].dealerButtonX = PlayersXY[3].chipX+Math.round(config.chipWidth/2)
  PlayersXY[3].dealerButtonY = PlayersXY[3].chipY+config.chipHeight+config.bettingChipFontSize
  PlayersXY[4].dealerButtonX = PlayersXY[4].chipX+config.chipWidth
  PlayersXY[4].dealerButtonY = PlayersXY[4].chipY+config.chipHeight+config.bettingChipFontSize
  PlayersXY[5].dealerButtonX = PlayersXY[5].chipX-config.dealerButtonWidth
  PlayersXY[5].dealerButtonY = PlayersXY[5].chipY+config.chipHeight
  PlayersXY[6].dealerButtonX = PlayersXY[6].chipX+Math.round(config.chipWidth/2)
  PlayersXY[6].dealerButtonY = PlayersXY[6].chipY-config.dealerButtonHeight-config.bettingChipFontSize
  PlayersXY[7].dealerButtonX = PlayersXY[7].chipX+Math.round(config.chipWidth/2)
  PlayersXY[7].dealerButtonY = PlayersXY[7].chipY-config.dealerButtonHeight-config.bettingChipFontSize
  PlayersXY[8].dealerButtonX = PlayersXY[8].chipX+Math.round(config.chipWidth/2)
  PlayersXY[8].dealerButtonY = PlayersXY[8].chipY-config.dealerButtonHeight-config.bettingChipFontSize
  PlayersXY[9].dealerButtonX = PlayersXY[9].chipX+Math.round(config.chipWidth/2)
  PlayersXY[9].dealerButtonY = PlayersXY[9].chipY-config.dealerButtonHeight-config.bettingChipFontSize
  return PlayersXY


dummyTableInfo = (playersNum, board) ->
  tableInfo = {
    board: board,
    players: []
  }
  for playerId in [0...playersNum]
    tableInfo.players[playerId] = {
      playerId: playerId,
      name: 'dummy'+playerId,
      hand: ['Ks', 'Ah'],
      stack: 15000,
      lastBet: 3500
    }
  return tableInfo

cardToCardNum = (card) ->
  switch card.charAt 1
    when 's' then cardNum = 0;  break;
    when 'c' then cardNum = 13; break;
    when 'd' then cardNum = 26; break;
    when 'h' then cardNum = 39; break;
    else return 53
  switch card.charAt 0
    when 'A' then cardNum+=0;  break;
    when 'K' then cardNum+=12; break;
    when 'Q' then cardNum+=11; break;
    when 'J' then cardNum+=10; break;
    when 'T' then cardNum+=9;  break;
    else cardNum+=(Number(card.charAt 0)-1);
  return  cardNum

setColorAndFont = (color,size) ->
  config.ctx.fillStyle = color
  config.ctx.font = size+"px \'Times New Roman\'"
