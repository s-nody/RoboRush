local UI = {}

function UI.draw(player)

    love.graphics.setColor(0.15, 0.15, 0.15)
    love.graphics.rectangle("fill", 20, 20, 200, 20)


    love.graphics.setColor(0.2, 0.9, 0.3)
    love.graphics.rectangle("fill", 20, 20, player.health * 2, 20)

    
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", 20, 20, 200, 20)

    love.graphics.print("HEALTH: " .. player.health, 20, 45)
end

return UI