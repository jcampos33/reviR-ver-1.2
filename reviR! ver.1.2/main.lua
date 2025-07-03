--push library to screen resolution
push = require 'push'

--Set window dimensions
virtual_width = 1280
virtual_height = 720

window_width = 1280
window_height = 720

--Initial game state and scaling for images
gameState = 'start'
scale = .15

--Load game assests and setups
function love.load()
    
   --Setting pixel scaling
    love.graphics.setDefaultFilter('nearest', 'nearest')
    love.window.setTitle('reviR!')

    --Setting virtual resolution with push
    push:setupScreen(virtual_width, virtual_height, window_width, window_height, {
        fullscreen = false,
        resizable = true,
        vsync = true
    })

    --Loading fonts
    smallFont = love.graphics.newFont('font.ttf', 30)
    bigFont = love.graphics.newFont('font.ttf', 80)
    love.graphics.setFont(smallFont)
    
    --Loading background image
    background = love.graphics.newImage('space.png')

    --Loading asteroid images
    asteroidsImage = {
        love.graphics.newImage("Spaceship/Asteroids/brown.png"),
        love.graphics.newImage("Spaceship/Asteroids/dark.png"),
        love.graphics.newImage("Spaceship/Asteroids/gray_2.png"),
        love.graphics.newImage("Spaceship/Asteroids/gray.png"),
    }

    --Initializing asteroid and missiles
    asteroids = {}
    asteroidsTimer = 0
    asteroidsInterval = 1

    missiles = {}
    missileTimer = 0
    missileInterval = .5

    --Loading missle images
    missileImage = {
        love.graphics.newImage("Spaceship/Blue/bullet.png"),
        love.graphics.newImage("Spaceship/Red/bullet_red.png")
    }
end

--Update gmae logic in real time
function love.update(dt)
    --Play state
   if gameState == 'play' then

        --Player 1 movement and boundaries
        if player1.active then
            if love.keyboard.isDown("a") then
                player1.x = player1.x - player1.speed * dt
                player1.sprite = player1.spriteLeft
            end
            if love.keyboard.isDown("d") then
                player1.x = player1.x + player1.speed * dt
                player1.sprite = player1.spriteRight
            end
            if love.keyboard.isDown("w") then
                player1.y = player1.y - player1.speed * dt
                player1.sprite = player1.spriteUp
            end 
            if love.keyboard.isDown("s") then
                player1.y = player1.y + player1.speed * dt
                player1.sprite = player1.spriteDown
            end

            --Setting player 1 screen boundaries
            p1w = player1.sprite:getWidth() * scale
            p1h = player1.sprite:getHeight() * scale
            player1.x = math.max(0, math.min(player1.x, love.graphics.getWidth() - p1w))
            player1.y = math.max(0, math.min(player1.y, love.graphics.getHeight() - p1h))
        end

        --Player 2 movement and boundaries(when active)
        if player2 and player2.active then
            if love.keyboard.isDown("left") then
                player2.x = player2.x - player2.speed * dt
                player2.sprite = player2.spriteLeft
            end
            if love.keyboard.isDown("right") then
                player2.x = player2.x + player2.speed * dt
                player2.sprite = player2.spriteRight
            end
            if love.keyboard.isDown("up") then
                player2.y = player2.y - player2.speed * dt
                player2.sprite = player2.spriteUp
            end 
            if love.keyboard.isDown("down") then
                player2.y = player2.y + player2.speed * dt
                player2.sprite = player2.spriteDown
            end

            --Setting player 2 screen boundaries
            p2w = player2.sprite:getWidth() * scale
            p2h = player2.sprite:getHeight() * scale
            player2.x = math.max(0, math.min(player2.x, love.graphics.getWidth() - p2w))
            player2.y = math.max(0, math.min(player2.y, love.graphics.getHeight() - p2h))
        end

        --Asteroids timing intervals
        asteroidsTimer = asteroidsTimer + dt
        if asteroidsTimer >= asteroidsInterval then
            spawnAsteroid()
            asteroidsTimer = 0
        end

        --Asteroids movements and removal
        for i = #asteroids, 1, -1 do
            asteroid = asteroids[i]
            asteroid.y = asteroid.y + asteroid.speed * dt

            if asteroid.y > love.graphics.getHeight() then
                table.remove(asteroids, i)
            end
        end

        --Missle and asteroid collision check
        for i = #missiles, 1, -1 do
            m = missiles[i]
            for j = #asteroids, 1, -1 do
                a = asteroids[j]
                if checkCollision(m, a, 3) then
                    --Score update
                    if m.image == missileImage[1] and player1 and player1.active then
                        player1.score = player1.score + 100
                    elseif m.image == missileImage[2] and player2 and player2.active then
                        player2.score = player2.score + 100
                    end

                    --Missile and asteriod removal after collision
                    table.remove(missiles, i)
                    table.remove(asteroids, j)
                    break
                end
            end
        end

        --Asteroid and player collision check
        for _, asteroid in ipairs(asteroids) do
            players = {player1, player2}
            for _, player in ipairs(players) do
                if player and player.active then
                    pw = player.sprite:getWidth() * scale
                    ph = player.sprite:getHeight() * scale
                    if checkCollision({x = player.x, y = player.y, width = pw, height = ph}, asteroid, 6) then
                        player.active = false
                    end
                end
            end
        end

        --Missiles shooting automatically
        missileTimer = missileTimer + dt
        if missileTimer >= missileInterval then
            if player1.active then
                spawnMissile(player1)
            end
            if player2 and player2.active then
                spawnMissile(player2)
            end
            missileTimer = 0
        end

        --Missile movement and removal
        for i = #missiles, 1, -1 do
            m = missiles[i]
            m.y = m.y - m.speed * dt
            if m.y < -10 then
                table.remove(missiles, i)
            end
        end
        
        --Game over state
        if (not player1.active) and (not player2 or not player2.active) then
            gameState = 'gameover'
        end
    elseif gameState == 'gameover' then
        --Restart game
        if love.keyboard.isDown('r') then
            resetGame()
        end
    end
end

--Keypress function
function love.keypressed(key)
    --Quit game
    if key == 'escape' then
        love.event.quit()
    --Move to menu or play gameState
    elseif key == 'return' then
        if gameState == 'start' then
            gameState = 'menu'
        elseif gameState == 'menu' then
            gameState = 'play'
        end
    --Number of players selection
    elseif gameState == 'menu' then
        if key == '1' then
            startGame(1)
        elseif key == '2' then
            startGame(2)
        end
    end

end

--Draw function
function love.draw()
    push:start()

    --Background drawing
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(background, 0, 0)

    --Start screen
    if gameState == 'start' then
        love.graphics.setColor(0,1,0)
        love.graphics.setFont(bigFont)
        love.graphics.printf('reviR!', 200 * 2.2, 200, 400, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Enter to begin!', 200 * 2.2, 300, 400, 'center')
    
    --Menu screen
    elseif gameState == 'menu' then
        love.graphics.setColor(0,1,0)
        love.graphics.setFont(smallFont)
        love.graphics.printf('Select number of players:', 200 * 2.2, 200, 400, 'center')
        love.graphics.printf('Press "1" for 1 Player', 200 * 2.2, 300, 400, 'center')
        love.graphics.printf('Press "2" for 2 Players', 200 * 2.2, 350, 400, 'center')

    --Gameplay screen
    elseif gameState == 'play' then
        --Drawing players
        if player1.active then
            love.graphics.draw(player1.sprite, player1.x, player1.y, 0, scale, scale)
        end

        if player2 and player2.active then
            love.graphics.draw(player2.sprite, player2.x, player2.y, 0, scale, scale)
        end

        --Drawing scores
        love.graphics.setFont(smallFont)
        love.graphics.setColor(0, 0, 1)
        if player1 then
            love.graphics.printf("P1 Score: " .. player1.score, 10, 10, 300, "left")
        end
        
        if player2 then
            love.graphics.setColor(1, 0, 0)
            love.graphics.printf("P2 Score: " .. player2.score, love.graphics.getWidth() - 310, 10, 300, "right")
        end
        
        --Drawing asteroids and missiles
        love.graphics.setColor(1, 1, 1)
        for _, asteroid in ipairs(asteroids) do
            love.graphics.draw(asteroid.image, asteroid.x, asteroid.y, 0, asteroid.scale, asteroid.scale)
        end

        for _, m in ipairs(missiles) do
            love.graphics.draw(m.image, m.x, m.y, 0, scale + .3, scale + .3)
        end
    
    --Gameover screen
    elseif gameState == 'gameover' then
        love.graphics.setColor(1, 0, 0)
        love.graphics.setFont(smallFont)
        love.graphics.printf('Game Over', 200 * 2.2, 200, 400, 'center')
        love.graphics.printf('Press "R" to restart', 200 * 2.2, 250, 400, 'center')
    end

    push:finish()
end

--Other functions to support game
--Initialize players and game state
function startGame(num)
    numPlayers = num
    gameState = 'play'

    --Player 1 setup
    if num == 1 then
        player1 = {
            x = 350 * 1.7,
            y = 400 * 1.3,
            speed = 300,
            active = true,
            score = 0,
            sprite = love.graphics.newImage('Spaceship/Blue/Small_ship_blue/3.png'),
            spriteRight = love.graphics.newImage('Spaceship/Blue/Small_ship_blue/4.png'),
            spriteLeft = love.graphics.newImage('Spaceship/Blue/Small_ship_blue/2.png'),
            spriteDown = love.graphics.newImage('Spaceship/Blue/Small_ship_blue/33.png'),
            spriteUp = love.graphics.newImage('Spaceship/Blue/Small_ship_blue/3.png'),
        }
        player2 = nil

    --Player 2 setup
    elseif num == 2 then
        player1 = {
            x = 250 * 1.6,
            y = 350 * 1.4,
            speed = 300,
            active = true,
            score = 0,
            sprite = love.graphics.newImage('Spaceship/Blue/Small_ship_blue/3.png'),
            spriteRight = love.graphics.newImage('Spaceship/Blue/Small_ship_blue/4.png'),
            spriteLeft = love.graphics.newImage('Spaceship/Blue/Small_ship_blue/2.png'),
            spriteDown = love.graphics.newImage('Spaceship/Blue/Small_ship_blue/33.png'),
            spriteUp = love.graphics.newImage('Spaceship/Blue/Small_ship_blue/3.png'),
        }
        
        player2 = {
            x = 450 * 1.6,
            y = 350 * 1.4,
            speed = 300,
            active = true,
            score = 0,
            sprite = love.graphics.newImage('Spaceship/Red/small_ship_animation/3.png'),
            spriteRight = love.graphics.newImage('Spaceship/Red/small_ship_animation/4.png'),
            spriteLeft = love.graphics.newImage('Spaceship/Red/small_ship_animation/2.png'),
            spriteDown = love.graphics.newImage('Spaceship/Red/small_ship_animation/33.png'),
            spriteUp = love.graphics.newImage('Spaceship/Red/small_ship_animation/3.png'),
        }
    end

end

--Random asteroid start
function spawnAsteroid()
    index = love.math.random(1, #asteroidsImage)
    image = asteroidsImage[index]
    asteroidScale = scale - 0.08
    width = image:getWidth() * asteroidScale
    height = image:getHeight() * asteroidScale

    asteroid = {
        image = image,
        x = love.math.random(0, love.graphics.getWidth() - width),
        y = -100,
        speed = love.math.random(100, 200),
        width = width,
        height = height,
        scale = asteroidScale
    }

    table.insert(asteroids, asteroid)
end

--Missile shooting from player location
function spawnMissile(player)
    image = (player == player1) and missileImage[1] or missileImage[2]
    missileScale = scale + .3
    width = image:getWidth() * missileScale
    height = image:getHeight() * missileScale
    
    missile = {
        image = image,
        x = player.x + (player.sprite:getWidth() * scale / 2) - (width / 2),
        y = player.y,
        speed = 400,
        width = width,
        height = height
    }
    table.insert(missiles, missile)
end

--AABB collision detection
function checkCollision(a, b, shrink)
    shrink = shrink or 0
    return a.x + shrink < b.x + b.width - shrink and
           b.x + shrink < a.x + a.width - shrink and
           a.y + shrink < b.y + b.height - shrink and
           b.y + shrink < a.y + a.height - shrink
end

--Reset game to initial start
function resetGame()
    if numPlayers == 1 then
        player1.x = 350 * 1.7
        player1.y = 400 * 1.3
        player1.active = true
        player2 = nil
    elseif numPlayers == 2 then
        player1.x = 250 * 1.6
        player1.y = 350 * 1.4
        player1.active = true

        player2.x = 450 * 1.6
        player2.y = 350 * 1.4
        player2.active = true
    end
    
    --Reset score and clearing missile/asteroids
    if player1 then
        player1.score = 0
    end
    if player2 then
        player2.score = 0
    end

    asteroids = {}
    missiles = {}
    asteroidsTimer = 0
    missileTimer = 0

    gameState = 'menu'
end

--Screen risizing
function love.resize(w, h)
    push:resize(w, h)
end
