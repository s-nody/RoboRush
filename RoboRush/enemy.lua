local collision = require("collision")

local Enemy = {}
Enemy.__index = Enemy

function Enemy.new(x1, y1, x2, y2, moveType)
    local self = setmetatable({}, Enemy)

    self.x = x1
    self.y = y1

    self.startX = x1
    self.startY = y1
    self.endX = x2
    self.endY = y2

    self.speed = 100
    self.dir = 1
    self.moveType = moveType or "horizontal"

    self.sprite = love.graphics.newImage("sprites/enemy.png")
    self.scaleX = 0.10
    self.scaleY = 0.10

  
    self.hitboxOffsetX = 8
    self.hitboxOffsetY = 18
    self.w = 48
    self.h = 24

    return self
end

function Enemy:update(dt)
    if self.moveType == "horizontal" then
        self.x = self.x + self.speed * self.dir * dt

        if self.x <= self.startX then
            self.x = self.startX
            self.dir = 1
        elseif self.x >= self.endX then
            self.x = self.endX
            self.dir = -1
        end

    elseif self.moveType == "vertical" then
        self.y = self.y + self.speed * self.dir * dt

        if self.y <= self.startY then
            self.y = self.startY
            self.dir = 1
        elseif self.y >= self.endY then
            self.y = self.endY
            self.dir = -1
        end
    end
end

function Enemy:checkCollision(player)
    return collision.aabb(
        self.x + self.hitboxOffsetX,
        self.y + self.hitboxOffsetY,
        self.w,
        self.h,
        player.x + player.hitboxOffsetX,
        player.y + player.hitboxOffsetY,
        player.w,
        player.h
    )
end

function Enemy:draw()
    love.graphics.setColor(1, 1, 1)

    love.graphics.draw(
        self.sprite,
        self.x,
        self.y,
        0,
        self.scaleX,
        self.scaleY
    )

   

    love.graphics.setColor(1, 1, 1, 1)
end

return Enemy