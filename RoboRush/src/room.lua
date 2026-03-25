local C = require("src.constants")
local enemy = require("src.enemy")

local R = {}

function R.generate(roomIndex, rng, evacMode)
  local margin = 56
  local bounds = {
    minX = margin,
    minY = margin,
    maxX = C.GAME_W - margin,
    maxY = C.GAME_H - margin,
  }

  local walls = {}
  local nBlocks = math.min(4, 1 + math.floor(rng() * 3) + math.floor(roomIndex / 3))
  for i = 1, nBlocks do
    local ww = 32 + math.floor(rng() * 5) * 32
    local wh = 32 + math.floor(rng() * 4) * 32
    local wx = bounds.minX + 80 + rng() * (bounds.maxX - bounds.minX - ww - 160)
    local wy = bounds.minY + 80 + rng() * (bounds.maxY - bounds.minY - wh - 160)
    walls[#walls + 1] = { x = wx, y = wy, w = ww, h = wh }
  end

  local spawnX = bounds.minX + 40
  local spawnY = bounds.minY + (bounds.maxY - bounds.minY) * 0.45

  local doorW, doorH = 44, 52
  local doorSide = math.floor(rng() * 4)
  local door = { w = doorW, h = doorH, locked = true }
  if doorSide == 0 then
    door.x = bounds.maxX - 8
    door.y = bounds.minY + 120 + rng() * (bounds.maxY - bounds.minY - 240 - doorH)
  elseif doorSide == 1 then
    door.x = bounds.minX - doorW + 8
    door.y = bounds.minY + 120 + rng() * (bounds.maxY - bounds.minY - 240 - doorH)
  elseif doorSide == 2 then
    door.x = bounds.minX + 120 + rng() * (bounds.maxX - bounds.minX - 240 - doorW)
    door.y = bounds.minY - doorH + 8
  else
    door.x = bounds.minX + 120 + rng() * (bounds.maxX - bounds.minX - 240 - doorW)
    door.y = bounds.maxY - 8
  end

  local node = {
    x = bounds.minX + 180 + rng() * (bounds.maxX - bounds.minX - 360 - 24),
    y = bounds.minY + 100 + rng() * (bounds.maxY - bounds.minY - 200 - 24),
    w = 24,
    h = 24,
    repaired = false,
  }

  local cells = {}
  local nCells = 2 + math.floor(rng() * 3) + math.floor(roomIndex * 0.25)
  for i = 1, nCells do
    cells[i] = {
      x = bounds.minX + 60 + rng() * (bounds.maxX - bounds.minX - 120 - 16),
      y = bounds.minY + 60 + rng() * (bounds.maxY - bounds.minY - 120 - 16),
      w = 16,
      h = 16,
      alive = true,
    }
  end

  local enemies = {}
  local nPatrol = 1 + math.floor(rng() * 2) + math.floor(roomIndex * C.DIFF_SPAWN_BONUS)
  local nHunt = math.floor(rng() * 2) + math.floor(roomIndex * C.DIFF_SPAWN_BONUS * 1.2)
  if evacMode then
    nPatrol = nPatrol + 2
    nHunt = nHunt + 3
  end
  for i = 1, nPatrol do
    enemies[#enemies + 1] = enemy.createPatrol(rng, bounds, walls)
  end
  for i = 1, nHunt do
    enemies[#enemies + 1] = enemy.createHunter(rng, bounds, roomIndex)
  end

  return {
    index = roomIndex,
    bounds = bounds,
    walls = walls,
    door = door,
    node = node,
    cells = cells,
    enemies = enemies,
    spawnX = spawnX,
    spawnY = spawnY,
  }
end

return R
