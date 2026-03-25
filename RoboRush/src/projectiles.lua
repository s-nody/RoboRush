local C = require("src.constants")
local col = require("src.collision")

local Proj = {}

function Proj.spawn(list, x, y, dirx, diry)
  local d = math.sqrt(dirx * dirx + diry * diry)
  if d < 0.001 then
    return
  end
  dirx, diry = dirx / d, diry / d
  list[#list + 1] = {
    x = x,
    y = y,
    w = 10,
    h = 10,
    vx = dirx * C.BULLET_SPEED,
    vy = diry * C.BULLET_SPEED,
    life = 1.4,
  }
end

function Proj.update(list, dt, bounds, walls)
  for i = #list, 1, -1 do
    local b = list[i]
    b.life = b.life - dt
    if b.life <= 0 then
      table.remove(list, i)
    else
      b.x = b.x + b.vx * dt
      b.y = b.y + b.vy * dt
      local dead = false
      if b.x < bounds.minX or b.y < bounds.minY or b.x + b.w > bounds.maxX or b.y + b.h > bounds.maxY then
        dead = true
      end
      if not dead then
        for _, w in ipairs(walls) do
          if col.aabb(b.x, b.y, b.w, b.h, w.x, w.y, w.w, w.h) then
            dead = true
            break
          end
        end
      end
      if dead then
        table.remove(list, i)
      end
    end
  end
end

return Proj
