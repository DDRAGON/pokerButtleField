
config =
  canvasWidth: 1000,
  canvasHeight: 600,
  cardWidth: 48,
  cardHeight: 64,
  state:  'loading',
  mouseListener: false,
  clockTime: false

imageName = ['Tranp.png']
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
  console.log '通信できたー！！'


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
setColorAndFont = (color,size) ->
  config.ctx.fillStyle = color
  config.ctx.font = size+"px \'Times New Roman\'"
