
config =
  canvasWidth: 1000,
  canvasHeight: 650,
  cardWidth: 48,
  cardHeight: 64,
  tableWidth: 750,
  tableHeight: 500,
  chipWidth: 32,
  chipHeight: 32,
  bettingChipFontSize: 14
  state:  'loading',
  mouseListener: false,
  clockTime: false,
  chipList: [1000, 500, 100, 20, 5, 1]

config.nameBoxWidth  = config.cardWidth*3
config.nameBoxHeight = Math.ceil(config.cardHeight*3/2)
config.tableX = Math.ceil(config.nameBoxWidth/2)
config.tableY = Math.ceil(config.nameBoxHeight/2)

imageName =
  [
    'Tranp.png', 'bg1.png', 'chip1.png', 'chip1.png', 'chip5.png', 'chip20.png', 'chip100.png',
    'chip500.png', 'chip1000.png'
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
  data = dummyTableInfo(10, ['As','Jd','2h','5h','3c'])
  config.ctx.clearRect(0, 0, config.canvasWidth, config.canvasHeight)
  config.ctx.drawImage(images['bg1.png'], config.tableX, config.tableY)
  playersXY = getPlayersXYByNum(data.players.length)
  for playerId, player of data.players
    drawX = playersXY[playerId].handsX
    drawY = playersXY[playerId].handsY
    # 手札の描画
    drawcard(cardToCardNum(player.hand[0]),drawX,drawY)
    drawX += config.cardWidth
    drawcard(cardToCardNum(player.hand[1]),drawX,drawY)
    # 名前空間の描画
    setColorAndFont('black', 11)
    config.ctx.fillRect(playersXY[playerId].nameX, playersXY[playerId].nameY, config.nameBoxWidth, config.nameBoxHeight);
    setColorAndFont('white', 20)
    config.ctx.fillText(player.name, playersXY[playerId].nameX+1, playersXY[playerId].nameY+Math.ceil(config.nameBoxHeight*2/5));
    config.ctx.fillText(player.stack, playersXY[playerId].nameX+1, playersXY[playerId].nameY+Math.ceil(config.nameBoxHeight*4/5));
    # チップの描画
    drawBettingChips(player.lastBet, playersXY[playerId].chipX, playersXY[playerId].chipY)



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
drawBettingChips = (chipAmount, x, y) ->
  chips = []
  drawX = x
  for chip of config.chipList
    chipMany = Math.floor(chipAmount/chip)
    for i in [0...chipMany]
      chips.push(chip)
    chipAmount -= chipMany*chip
  for i in [chips.length...0]
    chip = chips[i]
    if i%2 == 0
      drawX += config.chipWidth
    config.ctx.drawImage(images['chip'+chip+'.png'],drawX,y,config.chipWidth,config.chipHeight);



drawcard = (cardnum,x,y) ->
  cardmany = 10
  cutx = (cardnum %cardmany)*config.cardWidth;
  cuty = ((cardnum/cardmany) | 0)*config.cardHeight;
  config.ctx.drawImage(images["Tranp.png"],cutx,cuty,config.cardWidth,config.cardHeight,x,y,config.cardWidth,config.cardHeight);

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
  # チップ座標
  PlayersXY[0].chipX = PlayersXY[0].x +=  Math.ceil(config.nameBoxWidth/2)
  PlayersXY[0].chipY = PlayersXY[0].y +=  Math.ceil(config.cardHeight/4)
  PlayersXY[1].chipX = PlayersXY[1].x +=  Math.ceil(config.nameBoxWidth/2)
  PlayersXY[1].chipY = PlayersXY[1].y +=  Math.ceil(config.cardHeight/4)+config.nameBoxHeight
  PlayersXY[2].chipX = PlayersXY[2].x -=  config.chipWidth
  PlayersXY[2].chipY = PlayersXY[2].y +=  Math.ceil(config.cardHeight/4)+config.nameBoxHeight
  PlayersXY[3].chipX = PlayersXY[3].x -=  config.chipWidth
  PlayersXY[3].chipY = PlayersXY[3].y +=  Math.ceil(config.cardHeight/4)+config.nameBoxHeight
  PlayersXY[4].chipX = PlayersXY[4].x -=  (Math.ceil(config.nameBoxWidth/2)+config.chipWidth*2)
  PlayersXY[4].chipY = PlayersXY[4].y +=  Math.ceil(config.cardHeight/4)+config.nameBoxHeight
  PlayersXY[5].chipX = PlayersXY[5].x -=  (Math.ceil(config.nameBoxWidth/2)+config.chipWidth*2)
  PlayersXY[5].chipY = PlayersXY[5].y +=  Math.ceil(config.cardHeight/4)
  PlayersXY[6].chipX = PlayersXY[6].x -=  (Math.ceil(config.nameBoxWidth/2)+config.chipWidth*2)
  PlayersXY[6].chipY = PlayersXY[6].y +=  (Math.ceil(config.cardHeight/4)-config.chipHeight-config.bettingChipFontSize)
  PlayersXY[7].chipX = PlayersXY[7].x -=  config.chipWidth
  PlayersXY[7].chipY = PlayersXY[7].y +=  Math.ceil(config.cardHeight/4)-config.cardHeight-config.chipHeight-config.bettingChipFontSize
  PlayersXY[8].chipX = PlayersXY[8].x -=  config.chipWidth
  PlayersXY[8].chipY = PlayersXY[8].y +=  Math.ceil(config.cardHeight/4)-config.cardHeight-config.chipHeight-config.bettingChipFontSize
  PlayersXY[9].chipX = PlayersXY[9].x +=  (Math.ceil(config.nameBoxWidth/2)+config.chipWidth*2)
  PlayersXY[9].chipY = PlayersXY[9].y +=  (Math.ceil(config.cardHeight/4)-config.chipHeight-config.bettingChipFontSize)

  for i in [0...playersNum]
    PlayersXY[i].x += config.tableX
    PlayersXY[i].y += config.tableY
    PlayersXY[i].handsX = PlayersXY[i].x - config.cardWidth
    PlayersXY[i].handsY = PlayersXY[i].y - Math.ceil(config.nameBoxHeight/2)
    PlayersXY[i].nameX  = PlayersXY[i].x - Math.ceil(config.nameBoxWidth/2)
    PlayersXY[i].nameY  = PlayersXY[i].y + Math.ceil(config.cardHeight/4)
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
