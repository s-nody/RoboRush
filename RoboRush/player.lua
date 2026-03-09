local collision = require("collision")

local Player = {}
Player.__index = Player

function Player.new(x, y)
    local self = setmetatable({}, Player)

    self.x = x
    self.y = y

    self.hitboxOffsetX = 6
    self.hitboxOffsetY = 8
    self.w = 20
    self.h = 22

    self.speed = 180
    self.health = 100
    self.invulnTimer = 0

    self.direction = "down"
    self.animTimer = 0
    self.animSpeed = 0.15
    self.currentFrame = 1

    self.spriteSheet = love.graphics.newImage("sprites/player (2).png")

    local sheetW, sheetH = self.spriteSheet:getDimensions()
    local frameW = sheetW / 4
    local frameH = sheetH / 4

   
    self.quads = {
        down = {
            love.graphics.newQuad(0 * frameW, 0 * frameH, frameW, frameH, sheetW, sheetH),
            love.graphics.newQuad(1 * frameW, 0 * frameH, frameW, frameH, sheetW, sheetH),
            love.graphics.newQuad(2 * frameW, 0 * frameH, frameW, frameH, sheetW, sheetH),
            love.graphics.newQuad(3 * frameW, 0 * frameH, frameW, frameH, sheetW, sheetH)
        },
        left = {
            love.graphics.newQuad(0 * frameW, 1 * frameH, frameW, frameH, sheetW, sheetH),
            love.graphics.newQuad(1 * frameW, 1 * frameH, frameW, frameH, sheetW, sheetH),
            love.graphics.newQuad(2 * frameW, 1 * frameH, frameW, frameH, sheetW, sheetH),
            love.graphics.newQuad(3 * frameW, 1 * frameH, frameW, frameH, sheetW, sheetH)
        },
        right = {
            love.graphics.newQuad(0 * frameW, 1 * frameH, frameW, frameH, sheetW, sheetH),
            love.graphics.newQuad(1 * frameW, 1 * frameH, frameW, frameH, sheetW, sheetH),
            love.graphics.newQuad(2 * frameW, 1 * frameH, frameW, frameH, sheetW, sheetH),
            love.graphics.newQuad(3 * frameW, 1 * frameH, frameW, frameH, sheetW, sheetH)
        },
        up = {
            love.graphics.newQuad(0 * frameW, 3 * frameH, frameW, frameH, sheetW, sheetH),
            love.graphics.newQuad(1 * frameW, 3 * frameH, frameW, frameH, sheetW, sheetH),
            love.graphics.newQuad(2 * frameW, 3 * frameH, frameW, frameH, sheetW, sheetH),
            love.graphics.newQuad(3 * frameW, 3 * frameH, frameW, frameH, sheetW, sheetH)
        }
    }

    self.scaleX = 0.7
    self.scaleY = 0.7

    return self
end

function Player:update(dt, walls)
    local vx, vy = 0, 0
    local moving = false

    if love.keyboard.isDown("w") then
        vy = -self.speed
        self.direction = "up"
        moving = true
    end
    if love.keyboard.isDown("s") then
        vy = self.speed
        self.direction = "down"
        moving = true
    end
    if love.keyboard.isDown("a") then
        vx = -self.speed
        self.direction = "left"
        moving = true
    end
    if love.keyboard.isDown("d") then
        vx = self.speed
        self.direction = "right"
        moving = true
    end

    local nextX = self.x + vx * dt
    local nextY = self.y + vy * dt

    if not collision.checkWalls(
        nextX + self.hitboxOffsetX,
        self.y + self.hitboxOffsetY,
        self.w,
        self.h,
        walls
    ) then
        self.x = nextX
    end

    if not collision.checkWalls(
        self.x + self.hitboxOffsetX,
        nextY + self.hitboxOffsetY,
        self.w,
        self.h,
        walls
    ) then
        self.y = nextY
    end

    if moving then
        self.animTimer = self.animTimer + dt
        if self.animTimer >= self.animSpeed then
            self.animTimer = 0
            self.currentFrame = self.currentFrame + 1
            if self.currentFrame > 4 then
                self.currentFrame = 1
            end
        end
    else
        self.currentFrame = 1
    end

    if self.invulnTimer > 0 then
        self.invulnTimer = self.invulnTimer - dt
    end
end

function Player:draw()
    if self.invulnTimer > 0 then
        if math.floor(self.invulnTimer * 10) % 2 == 0 then
            love.graphics.setColor(1, 1, 1, 0.35)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
    else
        love.graphics.setColor(1, 1, 1, 1)
    end

    local sx = self.scaleX
    local drawX = self.x

    if self.direction == "right" then
        sx = -self.scaleX
        drawX = self.x + (self.spriteSheet:getWidth() / 4) * self.scaleX
    end

    love.graphics.draw(
        self.spriteSheet,
        self.quads[self.direction][self.currentFrame],
        drawX,
        self.y,
        0,
        sx,
        self.scaleY
    )

   
    love.graphics.setColor(1, 1, 1, 1)
end

return Player