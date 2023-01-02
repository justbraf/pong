-- https://github.com/Ulydev/push
push = require 'push'
Class = require 'class'

require 'paddle'
require 'ball'

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

PADDLE_SPEED = 200

function love.load()
  math.randomseed(os.time())

  love.graphics.setDefaultFilter('nearest', 'nearest')

  love.window.setTitle('Pong')

  smallFont = love.graphics.newFont("font.ttf", 8)
  largeFont = love.graphics.newFont("font.ttf", 16)
  scoreFont = love.graphics.newFont("font.ttf", 32)
  love.graphics.setFont(smallFont)

  sounds = {
    ['paddleHit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
    ['score'] = love.audio.newSource('sounds/score.wav', 'static'),
    ['wallHit'] = love.audio.newSource('sounds/wall_hit.wav', 'static'),
    -- added sound for winning game
    ['fanfare'] = love.audio.newSource('sounds/success-fanfare-trumpets-6185.mp3', 'stream')
  }

  push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
    fullscreen = false,
    resizable = true,
    vsync = true,
  })

  servingPlayer = 1

  playerOne = Paddle(10, 30, 5, 20)
  playerTwo = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 50, 5, 20)
  ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)

  gameState = 'start'
  -- track if game is one player or two player
  gameMode = 0
  -- set difficulty of game
  gameDifficulty = 'easy'
  -- based on difficulty level the speed of the computer's paddle is adjusted
  cpuSpeedAdj = 0
  -- flag to ensure winning music is played only once
  playedFanfare = false

end

function love.resize(w, h)
  push:resize(w, h)
end

function love.update(dt)
  if gameState == 'serve' then
    ball.dy = math.random(-50, 50)
    if servingPlayer == 1 then
      ball.dx = math.random(140, 200)
    else
      ball.dx = -math.random(140, 200)
    end
  elseif gameState == 'play' then
    -- detect collisions
    if ball:collides(playerOne) then
      ball.dx = -ball.dx * 1.03
      ball.x = playerOne.x + 5

      if ball.dy < 0 then
        ball.dy = -math.random(10, 150)
      else
        ball.dy = math.random(10, 150)
      end
      sounds['paddleHit']:play()
    end
    if ball:collides(playerTwo) then
      ball.dx = -ball.dx * 1.03
      ball.x = playerTwo.x - 4

      if ball.dy < 0 then
        ball.dy = -math.random(10, 150)
      else
        ball.dy = math.random(10, 150)
      end
      sounds['paddleHit']:play()
    end

    if ball.y <= 0 then
      ball.y = 0
      ball.dy = -ball.dy
      sounds['wallHit']:play()
    end

    if ball.y >= VIRTUAL_HEIGHT - 4 then
      ball.y = VIRTUAL_HEIGHT - 4
      ball.dy = -ball.dy
      sounds['wallHit']:play()
    end

    -- do score
    if ball.x < 0 then
      servingPlayer = 1
      playerTwo.score = playerTwo.score + 1
      sounds['score']:play()
      if playerTwo.score == 3 then
        winningPlayer = 2
        gameState = 'done'
      else
        gameState = 'serve'
        ball:reset()
      end
    end

    if ball.x > VIRTUAL_WIDTH then
      servingPlayer = 2
      playerOne.score = playerOne.score + 1
      sounds['score']:play()
      if playerOne.score == 3 then
        winningPlayer = 1
        gameState = 'done'
      else
        gameState = 'serve'
        ball:reset()
      end
    end
  end

  -- player 1 mode is user
  if gameMode == 2 then
    if love.keyboard.isDown('w') then
      playerOne.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('s') then
      playerOne.dy = PADDLE_SPEED
    else
      playerOne.dy = 0
    end
    -- Player 1 mode is computer
  elseif gameMode == 1 and gameState == 'play' then
    -- set difficulty level based on user's choice
    if gameDifficulty == 'easy' then
      cpuSpeedAdj = 125
    elseif gameDifficulty == 'normal' then
      cpuSpeedAdj = 100
    elseif gameDifficulty == 'infinite' then
      cpuSpeedAdj = 0
    end
    if ball.y < playerOne.y + playerOne.height / 2 then
      playerOne.dy = -PADDLE_SPEED + cpuSpeedAdj
    elseif ball.y > playerOne.y + playerOne.height / 2 then
      playerOne.dy = PADDLE_SPEED - cpuSpeedAdj
    end
  end
  -- player 2
  if love.keyboard.isDown('up') then
    playerTwo.dy = -PADDLE_SPEED
  elseif love.keyboard.isDown('down') then
    playerTwo.dy = PADDLE_SPEED
  else
    playerTwo.dy = 0
  end

  if gameState == 'play' then
    ball:update(dt)
  end

  playerOne:update(dt)
  playerTwo:update(dt)
end

function love.keypressed(key)
  if key == 'escape' then
    love.event.quit()
  elseif key == '1' and gameState == 'start' then
    gameState = 'select'
  elseif key == 'e' and gameState == 'select' then
    gameMode = 1
    gameDifficulty = 'easy'
    gameState = 'serve'
  elseif key == 'n' and gameState == 'select' then
    gameMode = 1
    gameDifficulty = 'normal'
    gameState = 'serve'
  elseif key == 'i' and gameState == 'select' then
    gameMode = 1
    gameDifficulty = 'infinite'
    gameState = 'serve'
  elseif key == '2' and gameState == 'start' then
    gameMode = 2
    gameState = 'serve'
  elseif key == 'q' and gameState == 'done' then
    -- reset game stats and return to main menu
    ball:reset()
    playerOne.score = 0
    playerTwo.score = 0
    gameMode = 0
    gameState = 'start'
    playedFanfare = false
  elseif key == 'space' and (gameMode == 1 or gameMode == 2) then
    -- start game play once user has selected mode
    if gameState == 'serve' then
      gameState = 'play'
    elseif gameState == 'done' then
      -- reset game stats for a new round
      ball:reset()
      playerOne.score = 0
      playerTwo.score = 0
      gameState = 'serve'
      playedFanfare = false

      if winningPlayer == 1 then
        servingPlayer = 2
      else
        servingPlayer = 1
      end
    end
  end
end

function love.draw()
  push:apply('start')
  love.graphics.clear(40 / 255, 45 / 255, 52 / 255, 255 / 255)

  if gameState == 'serve' or gameState == 'play' or gameState == 'done' then
    displayScore()
  end

  if gameState == 'start' then
    love.graphics.setFont(smallFont)
    love.graphics.printf('Welcome to Pong!', 0, 10, VIRTUAL_WIDTH, 'center')
    love.graphics.printf('Press 1 for One Player Mode!', 0, 20, VIRTUAL_WIDTH, 'center')
    love.graphics.printf('Press 2 for Two Player Mode!', 0, 30, VIRTUAL_WIDTH, 'center')
  elseif gameState == 'select' then
    love.graphics.rectangle('line', VIRTUAL_WIDTH / 2 - 80, 30, 160, 60)
    love.graphics.setFont(smallFont)
    love.graphics.printf('Please select your mode!', 0, 40, VIRTUAL_WIDTH, 'center')
    love.graphics.printf('E - Easy', 0, 50, VIRTUAL_WIDTH, 'center')
    love.graphics.printf('N - Normal', 0, 60, VIRTUAL_WIDTH, 'center')
    love.graphics.printf('I - Infinite', 0, 70, VIRTUAL_WIDTH, 'center')
  elseif gameState == 'serve' then
    love.graphics.setFont(smallFont)
    love.graphics.printf('Player ' .. tostring(servingPlayer) .. "'s serve!", 0, 10, VIRTUAL_WIDTH, 'center')
    love.graphics.printf('Press Space Bar to serve!', 0, 20, VIRTUAL_WIDTH, 'center')
  elseif gameState == 'play' then
    -- nothing to do
  elseif gameState == 'done' then
    love.graphics.setFont(smallFont)
    -- Show winner as CPU
    if gameMode == 1 and winningPlayer == 1 then
      love.graphics.printf('CPU wins!', 0, 10, VIRTUAL_WIDTH, 'center')
    else
      -- Otherwise just show which player won
      love.graphics.printf('Player ' .. tostring(winningPlayer) .. ' wins!', 0, 10, VIRTUAL_WIDTH, 'center')
    end
    -- play winning music once
    if not playedFanfare then
      sounds['fanfare']:play()
      playedFanfare = true
    end
    love.graphics.printf('Press Space Bar to restart!', 0, 20, VIRTUAL_WIDTH, 'center')
    love.graphics.printf('or Press Q to return to menu!', 0, 30, VIRTUAL_WIDTH, 'center')
  end

  playerOne:render()
  playerTwo:render()

  ball:render()

  displayFPS()

  push:apply('end')
end

function displayFPS()
  love.graphics.setFont(smallFont)
  love.graphics.setColor(0, 1, 0, 1)
  love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
end

function displayScore()
  love.graphics.setFont(scoreFont)
  love.graphics.print(tostring(playerOne.score), VIRTUAL_WIDTH / 2 - 50, VIRTUAL_HEIGHT / 3)
  love.graphics.print(tostring(playerTwo.score), VIRTUAL_WIDTH / 2 + 50, VIRTUAL_HEIGHT / 3)
end
