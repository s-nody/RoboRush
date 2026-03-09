local collision = {}

function collision.aabb(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and
           x2 < x1 + w1 and
           y1 < y2 + h2 and
           y2 < y1 + h1
end

function collision.checkWalls(x, y, w, h, walls)
    for _, wall in ipairs(walls) do
        if collision.aabb(x, y, w, h, wall.x, wall.y, wall.w, wall.h) then
            return true
        end
    end
    return false
end

return collision