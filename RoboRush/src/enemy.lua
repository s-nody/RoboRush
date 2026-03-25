local C = require("src.constants")
local col = require("src.collision")

local E = {}

local function len(dx, dy)
  return math.sqrt(dx * dx + dy * dy)
end

function E.createPatrol(rng, bounds, walls)
  local w, h = 30, 30
  local axis = rng() < 0.5 and "h" or "v"
  local margin = 80
  local minx, miny = bounds.minX + margin, bounds.minY + margin
  local maxx, maxy = bounds.maxX - margin - w, bounds.maxY - margin - h
  local cx = minx + rng() * (maxx - minx)
  local cy = miny + rng() * (maxy - miny)
  local span = 120 + rng() * 180
  local p1x, p1y, p2x, p2y
  if axis == "h" then
    p1x, p1y = cx - span * 0.5, cy
    p2x, p2y = cx + span * 0.5, cy
  else
    p1x, p1y = cx, cy - span * 0.5
    p2x, p2y = cx, cy + span * 0.5
  end
  return {
    kind = "patrol",
    state = "patrol",
    x = p1x,
    y = p1y,
    w = w,
    h = h,
    p1x = p1x,
    p1y = p1y,
    p2x = p2x,
    p2y = p2y,
    tx = p2x,
    ty = p2y,
    hp = C.PATROL_DRONE_HP,
    maxHp = C.PATROL_DRONE_HP,
    axis = axis,
  }
end

function E.createHunter(rng, bounds, roomIndex)
  local w, h = 30, 30
  local margin = 100
  local minx, miny = bounds.minX + margin, bounds.minY + margin
  local maxx, maxy = bounds.maxX - margin - w, bounds.maxY - margin - h
  local hx = minx + rng() * (maxx - minx)
  local hy = miny + rng() * (maxy - miny)
  local span = 80 + rng() * 100
  return {
    kind = "hunter",
    state = "patrol",
    x = hx,
    y = hy,
    w = w,
    h = h,
    homeX = hx,
    homeY = hy,
    hp = C.HUNTER_DRONE_HP,
    maxHp = C.HUNTER_DRONE_HP,
    paX = hx - span,
    paY = hy,
    pbX = hx + span,
    pbY = hy,
    tx = hx + span,
    ty = hy,
    angle = 0,
    detectBase = 160 + roomIndex * C.DIFF_DETECT_PER_ROOM,
  }
end

local function resolveWalls(e, walls, nx, ny)
  local x, y = nx, ny
  for _, wall in ipairs(walls) do
    if col.aabb(x, y, e.w, e.h, wall.x, wall.y, wall.w, wall.h) then
      return e.x, e.y
    end
  end
  return nx, ny
end

function E.updatePatrol(e, dt, speed, bounds, walls)
  local dx = e.tx - e.x
  local dy = e.ty - e.y
  local d = len(dx, dy)
  if d < 2 then
    if e.tx == e.p2x then
      e.tx, e.ty = e.p1x, e.p1y
    else
      e.tx, e.ty = e.p2x, e.p2y
    end
    dx = e.tx - e.x
    dy = e.ty - e.y
    d = len(dx, dy)
  end
  if d > 0 then
    e.x = e.x + (dx / d) * speed * dt
    e.y = e.y + (dy / d) * speed * dt
  end
  e.x = math.max(bounds.minX, math.min(bounds.maxX - e.w, e.x))
  e.y = math.max(bounds.minY, math.min(bounds.maxY - e.h, e.y))
  e.x, e.y = resolveWalls(e, walls, e.x, e.y)
end

function E.updateHunter(e, dt, speedPatrol, speedChase, px, py, pw, ph, bounds, walls, detectMult)
  local pcx, pcy = px + pw / 2, py + ph / 2
  local ecx, ecy = e.x + e.w / 2, e.y + e.h / 2
  local dist = len(pcx - ecx, pcy - ecy)
  local detect = e.detectBase * detectMult

  if e.state == "idle" then
    e.angle = e.angle + dt * 2.5
  elseif e.state == "patrol" then
    if dist < detect then
      e.state = "chase"
    else
      local dx = e.tx - e.x
      local dy = e.ty - e.y
      local d = len(dx, dy)
      if d < 3 then
        if e.tx == e.pbX then
          e.tx, e.ty = e.paX, e.paY
        else
          e.tx, e.ty = e.pbX, e.pbY
        end
      end
      dx = e.tx - e.x
      dy = e.ty - e.y
      d = len(dx, dy)
      if d > 0 then
        e.x = e.x + (dx / d) * speedPatrol * dt
        e.y = e.y + (dy / d) * speedPatrol * dt
      end
    end
  elseif e.state == "chase" then
    if dist > detect * 1.2 then
      e.state = "return"
    else
      local dx = pcx - ecx
      local dy = pcy - ecy
      local d = len(dx, dy)
      if d > 0 then
        e.x = e.x + (dx / d) * speedChase * dt
        e.y = e.y + (dy / d) * speedChase * dt
      end
    end
  elseif e.state == "return" then
    local hx, hy = e.homeX, e.homeY
    local dx = hx - e.x
    local dy = hy - e.y
    local d = len(dx, dy)
    if d < 8 then
      e.x, e.y = hx, hy
      e.state = "patrol"
      e.tx, e.ty = e.pbX, e.pbY
    else
      e.x = e.x + (dx / d) * speedPatrol * dt
      e.y = e.y + (dy / d) * speedPatrol * dt
    end
  end

  e.x = math.max(bounds.minX, math.min(bounds.maxX - e.w, e.x))
  e.y = math.max(bounds.minY, math.min(bounds.maxY - e.h, e.y))
  e.x, e.y = resolveWalls(e, walls, e.x, e.y)
end

function E.update(e, dt, ctx)
  if e.hp <= 0 then
    return
  end
  local mult = ctx.difficultySpeedMult
  if e.kind == "patrol" then
    local sp = C.BASE_PATROL_SPEED * mult
    E.updatePatrol(e, dt, sp, ctx.bounds, ctx.walls)
  else
    local spP = C.BASE_HUNTER_PATROL_SPEED * mult
    local spC = (C.BASE_HUNT_SPEED + ctx.elapsed * C.DIFF_SPEED_PER_SEC) * mult
    E.updateHunter(e, dt, spP, spC, ctx.px, ctx.py, ctx.pw, ctx.ph, ctx.bounds, ctx.walls, ctx.detectMult)
  end
end

return E
