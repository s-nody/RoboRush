local C = require("src.constants")
local col = require("src.collision")

local P = {}

function P.create()
  return {
    x = 200,
    y = 200,
    w = 28,
    h = 28,
    vx = 0,
    vy = 0,
    hp = C.PLAYER_MAX_HP,
    maxHp = C.PLAYER_MAX_HP,
    energy = C.PLAYER_MAX_ENERGY,
    maxEnergy = C.PLAYER_MAX_ENERGY,
    dashT = 0,
    dashCd = 0,
    dashVx = 0,
    dashVy = 0,
    invuln = 0,
    animT = 0,
    animFrame = 1,
    facing = 1,
    knockVx = 0,
    knockVy = 0,
    shootCd = 0,
    score = 0,
    survivalTime = 0,
  }
end

function P.reset(p, spawnX, spawnY)
  p.x, p.y = spawnX, spawnY
  p.vx, p.vy = 0, 0
  p.hp = p.maxHp
  p.energy = p.maxEnergy
  p.dashT = 0
  p.dashCd = 0
  p.invuln = 0
  p.knockVx, p.knockVy = 0, 0
  p.shootCd = 0
  p.score = 0
  p.survivalTime = 0
end

function P.update(p, dt, input, boundsMinX, boundsMinY, boundsMaxX, boundsMaxY)
  p.survivalTime = p.survivalTime + dt
  if p.shootCd > 0 then
    p.shootCd = p.shootCd - dt
  end
  if p.invuln > 0 then
    p.invuln = p.invuln - dt
  end
  if p.dashCd > 0 then
    p.dashCd = p.dashCd - dt
  end

  p.knockVx = p.knockVx * math.exp(-10 * dt)
  p.knockVy = p.knockVy * math.exp(-10 * dt)
  if math.abs(p.knockVx) < 1 then
    p.knockVx = 0
  end
  if math.abs(p.knockVy) < 1 then
    p.knockVy = 0
  end

  if p.dashT > 0 then
    p.dashT = p.dashT - dt
    p.vx = p.dashVx
    p.vy = p.dashVy
  else
    local ax, ay = 0, 0
    if input.left then
      ax = ax - 1
    end
    if input.right then
      ax = ax + 1
    end
    if input.up then
      ay = ay - 1
    end
    if input.down then
      ay = ay + 1
    end
    if ax ~= 0 or ay ~= 0 then
      local len = math.sqrt(ax * ax + ay * ay)
      ax, ay = ax / len, ay / len
    end
    p.vx = p.vx + ax * C.PLAYER_ACCEL * dt + p.knockVx
    p.vy = p.vy + ay * C.PLAYER_ACCEL * dt + p.knockVy

    local fr = math.exp(-C.PLAYER_FRICTION * dt)
    if ax == 0 then
      p.vx = p.vx * fr
    end
    if ay == 0 then
      p.vy = p.vy * fr
    end

    local sp = math.sqrt(p.vx * p.vx + p.vy * p.vy)
    if sp > C.PLAYER_MAX_SPEED then
      local s = C.PLAYER_MAX_SPEED / sp
      p.vx, p.vy = p.vx * s, p.vy * s
    end
  end

  p.x = p.x + p.vx * dt
  p.y = p.y + p.vy * dt
  p.x, p.y = col.clampToRect(p.x, p.y, p.w, p.h, boundsMinX, boundsMinY, boundsMaxX, boundsMaxY)

  local sp = math.sqrt(p.vx * p.vx + p.vy * p.vy)
  if math.abs(p.vx) > 10 then
    p.facing = p.vx > 0 and 1 or -1
  end
  local moving = (input.left or input.right or input.up or input.down) and p.dashT <= 0
  if moving and sp > 20 then
    p.animT = p.animT + dt * 10
    p.animFrame = (math.floor(p.animT) % 4) + 1
  else
    p.animT = 0
    p.animFrame = 1
  end

  p.energy = math.min(p.maxEnergy, p.energy + C.ENERGY_REGEN * dt)
end

function P.tryDash(p, input)
  if p.dashT > 0 or p.dashCd > 0 then
    return false
  end
  local dx, dy = 0, 0
  if input.left then
    dx = dx - 1
  end
  if input.right then
    dx = dx + 1
  end
  if input.up then
    dy = dy - 1
  end
  if input.down then
    dy = dy + 1
  end
  if dx == 0 and dy == 0 then
    return false
  end
  if p.energy < C.DASH_ENERGY_COST then
    return false
  end
  local len = math.sqrt(dx * dx + dy * dy)
  dx, dy = dx / len, dy / len
  p.energy = p.energy - C.DASH_ENERGY_COST
  p.dashT = C.DASH_DURATION
  p.dashCd = C.DASH_COOLDOWN
  p.dashVx = dx * C.DASH_SPEED
  p.dashVy = dy * C.DASH_SPEED
  return true
end

function P.takeDamage(p, amount, fromX, fromY, fromW, fromH)
  if p.invuln > 0 then
    return false
  end
  p.hp = p.hp - amount
  p.invuln = C.INVULN_TIME
  local cx, cy = p.x + p.w / 2, p.y + p.h / 2
  local ox = fromX + fromW / 2
  local oy = fromY + fromH / 2
  local dx, dy = cx - ox, cy - oy
  local d = math.sqrt(dx * dx + dy * dy)
  if d < 1 then
    dx, dy = 1, 0
    d = 1
  end
  local k = 420
  p.knockVx = p.knockVx + (dx / d) * k
  p.knockVy = p.knockVy + (dy / d) * k
  return true
end

function P.canShoot(p)
  return p.shootCd <= 0 and p.energy >= C.SHOOT_ENERGY_COST
end

function P.applyShootCost(p)
  p.energy = p.energy - C.SHOOT_ENERGY_COST
  p.shootCd = C.SHOOT_COOLDOWN
end

return P
