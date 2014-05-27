
config =
  canvasWidth: 1000,
  canvasHeight: 600,
  cardWidth: 48,
  cardHeight: 64,
  state:  'loading',
  mouseListener: false,
  clockTime: false

imageName = ['Tranp.png', 'bg1.png']
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
  config.ctx.drawImage(images['bg1.png'], 0, 0)
  for playerId, player of data.players
    drawX = playerId*config.cardWidth*2
    drawY = 200
    console.log player.hand[0]
    drawcard(cardToCardNum(player.hand[0]),drawX,drawY)
    drawX += config.cardWidth
    drawcard(cardToCardNum(player.hand[1]),drawX,drawY)


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
drawcard = (cardnum,x,y) ->
  cardmany = 10
  cutx = (cardnum %cardmany)*config.cardWidth;
  cuty = ((cardnum/cardmany) | 0)*config.cardHeight;
  config.ctx.drawImage(images["Tranp.png"],cutx,cuty,config.cardWidth,config.cardHeight,x,y,config.cardWidth,config.cardHeight);

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
