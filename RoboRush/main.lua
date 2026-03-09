local Player = require("player")
local Enemy = require("enemy")
local UI = require("ui")

player = nil
enemies = {}
walls = {}
gameState = "playing"
hitSound = nil

function love.load()
    love.window.setMode(900, 700)
    love.window.setTitle("Eclipse Protocol - Phase 1")

    math.randomseed(os.time())

    player = Player.new(120, 120)

    enemies = {
        Enemy.new(300, 250, 550, 250, "horizontal")
    }

    walls = {
        {x = 0, y = 0, w = 900, h = 20},
        {x = 0, y = 680, w = 900, h = 20},
        {x = 0, y = 0, w = 20, h = 700},
        {x = 880, y = 0, w = 20, h = 700}
    }

    hitSound = love.audio.newSource("sounds/hit.wav", "static")
    gameState = "playing"
end

function love.update(dt)
    if gameState ~= "playing" then
        return
    end

    player:update(dt, walls)

    for _, enemy in ipairs(enemies) do
        enemy:update(dt)

        if enemy:checkCollision(player) and player.invulnTimer <= 0 then
            player.health = player.health - 10
            player.invulnTimer = 1.0

            hitSound:stop()
            hitSound:play()

       
            if player.x < enemy.x then
                player.x = player.x - 25
            else
                player.x = player.x + 25
            end

            if player.y < enemy.y then
                player.y = player.y - 25
            else
                player.y = player.y + 25
            end
        end
    end

    if player.health <= 0 then
        gameState = "gameover"
    end
end

function love.draw()
    if gameState == "playing" then
        love.graphics.clear(0.08, 0.10, 0.14)

        love.graphics.setColor(0.14, 0.17, 0.22)
        for y = 20, 660, 64 do
            for x = 20, 860, 64 do
                love.graphics.rectangle("line", x, y, 64, 64)
            end
        end

        love.graphics.setColor(0.25, 0.30, 0.38)
        for _, wall in ipairs(walls) do
            love.graphics.rectangle("fill", wall.x, wall.y, wall.w, wall.h)
        end

        for _, enemy in ipairs(enemies) do
            enemy:draw()
        end

        player:draw()
        UI.draw(player)

    elseif gameState == "gameover" then
        love.graphics.clear(0.05, 0.05, 0.05)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("GAME OVER", 0, 300, 900, "center")
        love.graphics.printf("Press R to Restart", 0, 340, 900, "center")
    end
end

function love.keypressed(key)
    if gameState == "gameover" and key == "r" then
        love.load()
    end
end