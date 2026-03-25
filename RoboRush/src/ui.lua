local C = require("src.constants")
local col = require("src.collision")

local UI = {}

function UI.drawBackground()
  local w, h = love.graphics.getDimensions()
  for i = 0, 24 do
    local t = i / 24
    love.graphics.setColor(0.04 + t * 0.06, 0.06 + t * 0.1, 0.14 + t * 0.12, 1)
    love.graphics.rectangle("fill", 0, (h / 24) * i, w, h / 24 + 1)
  end
  love.graphics.setColor(0.12, 0.2, 0.28, 0.25)
  local step = 48
  for x = 0, w, step do
    love.graphics.line(x, 0, x, h)
  end
  for y = 0, h, step do
    love.graphics.line(0, y, w, y)
  end
  love.graphics.setColor(1, 1, 1, 1)
end

function UI.drawRoom(room, evacTimer)
  local r = room
  love.graphics.setColor(0.18, 0.22, 0.3, 1)
  for _, wall in ipairs(r.walls) do
    love.graphics.rectangle("fill", wall.x, wall.y, wall.w, wall.h, 4, 4)
    love.graphics.setColor(0.35, 0.55, 0.75, 0.35)
    love.graphics.rectangle("line", wall.x, wall.y, wall.w, wall.h, 4, 4)
    love.graphics.setColor(0.18, 0.22, 0.3, 1)
  end

  local d = r.door
  if d.locked then
    love.graphics.setColor(0.85, 0.25, 0.35, 0.85)
  else
    love.graphics.setColor(0.25, 0.9, 0.65, 0.75)
  end
  love.graphics.rectangle("fill", d.x, d.y, d.w, d.h, 6, 6)
  love.graphics.setColor(1, 1, 1, 0.4)
  love.graphics.rectangle("line", d.x, d.y, d.w, d.h, 6, 6)

  local n = r.node
  if not n.repaired then
    local pulse = 0.6 + 0.4 * math.sin(love.timer.getTime() * 5)
    love.graphics.setColor(0.95 * pulse, 0.75 * pulse, 0.2, 1)
    love.graphics.rectangle("fill", n.x, n.y, n.w, n.h, 4, 4)
    love.graphics.setColor(1, 0.95, 0.6, 0.5)
    love.graphics.rectangle("line", n.x - 2, n.y - 2, n.w + 4, n.h + 4, 4, 4)
  else
    love.graphics.setColor(0.35, 0.85, 0.45, 1)
    love.graphics.rectangle("fill", n.x, n.y, n.w, n.h, 4, 4)
  end

  for _, cell in ipairs(r.cells) do
    if cell.alive then
      love.graphics.setColor(0.5, 1, 0.75, 1)
      love.graphics.rectangle("fill", cell.x, cell.y, cell.w, cell.h, 3, 3)
    end
  end

  if evacTimer then
    love.graphics.setColor(1, 0.35, 0.2, 0.15 + 0.1 * math.sin(love.timer.getTime() * 12))
    love.graphics.rectangle("fill", r.bounds.minX, r.bounds.minY, r.bounds.maxX - r.bounds.minX, r.bounds.maxY - r.bounds.minY)
  end
  love.graphics.setColor(1, 1, 1, 1)
end

function UI.drawEnemies(room, sprites)
  for _, e in ipairs(room.enemies) do
    if e.hp > 0 then
      local quad = e.kind == "patrol" and sprites.patrolQuad or sprites.hunterQuad
      local shake = (e.kind == "hunter" and e.state == "chase") and 1 or 0
      local ox = shake * math.sin(love.timer.getTime() * 40) * 0.5
      love.graphics.setColor(1, 1, 1, 1)
      local rot = (e.kind == "hunter") and ((e.angle or 0) * 0.08) or 0
      love.graphics.draw(sprites.enemySheet, quad, e.x + ox, e.y, rot, 1, 1)
      local ratio = e.hp / e.maxHp
      love.graphics.setColor(0.15, 0.15, 0.2, 0.9)
      love.graphics.rectangle("fill", e.x, e.y - 8, e.w, 4, 2, 2)
      love.graphics.setColor(0.9, 0.35, 0.35, 1)
      love.graphics.rectangle("fill", e.x, e.y - 8, e.w * ratio, 4, 2, 2)
    end
  end
  love.graphics.setColor(1, 1, 1, 1)
end

function UI.drawPlayer(p, sprites)
  local vis = true
  if p.invuln > 0 then
    vis = math.floor(p.invuln * 12) % 2 == 0
  end
  if vis then
    love.graphics.setColor(1, 1, 1, 1)
    local sx = p.facing < 0 and -1 or 1
    love.graphics.draw(sprites.playerSheet, sprites.playerQuads[p.animFrame], p.x + p.w / 2, p.y + p.h / 2, 0, sx, 1, 16, 16)
  end
end

function UI.drawBullets(bullets)
  love.graphics.setColor(0.4, 0.95, 1, 1)
  for _, b in ipairs(bullets) do
    love.graphics.circle("fill", b.x + b.w / 2, b.y + b.h / 2, 5)
    love.graphics.setColor(0.85, 1, 1, 0.45)
    love.graphics.circle("line", b.x + b.w / 2, b.y + b.h / 2, 8)
    love.graphics.setColor(0.4, 0.95, 1, 1)
  end
  love.graphics.setColor(1, 1, 1, 1)
end

function UI.drawHUD(world)
  local p = world.player
  local x, y = 24, 20
  love.graphics.setColor(0.08, 0.1, 0.14, 0.85)
  love.graphics.rectangle("fill", x - 8, y - 8, 340, 118, 10, 10)
  love.graphics.setColor(0.35, 0.55, 0.8, 0.6)
  love.graphics.rectangle("line", x - 8, y - 8, 340, 118, 10, 10)

  love.graphics.setColor(0.55, 0.15, 0.2, 1)
  love.graphics.rectangle("fill", x, y, 220, 18, 4, 4)
  love.graphics.setColor(0.25, 0.9, 0.45, 1)
  love.graphics.rectangle("fill", x, y, 220 * (p.hp / p.maxHp), 18, 4, 4)
  love.graphics.setColor(1, 1, 1, 0.9)
  love.graphics.print("HULL", x + 6, y + 2)

  love.graphics.setColor(0.15, 0.2, 0.35, 1)
  love.graphics.rectangle("fill", x, y + 34, 220, 18, 4, 4)
  love.graphics.setColor(0.35, 0.75, 1, 1)
  love.graphics.rectangle("fill", x, y + 34, 220 * (p.energy / p.maxEnergy), 18, 4, 4)
  love.graphics.setColor(0.9, 0.95, 1, 0.95)
  love.graphics.print("ENERGY", x + 6, y + 36)

  love.graphics.setColor(0.85, 0.9, 1, 1)
  love.graphics.print("SCORE  " .. tostring(math.floor(p.score)), x, y + 68)
  love.graphics.print("TIME   " .. string.format("%.0fs", p.survivalTime), x, y + 88)
  love.graphics.print("NODES  " .. tostring(world.nodesRepaired) .. " / " .. tostring(C.NODES_TO_STABILIZE), x + 160, y + 68)

  if world.room then
    love.graphics.print("SECTOR " .. tostring(world.room.index), x + 160, y + 88)
  end

  if world.evacTimer then
    love.graphics.setColor(1, 0.45, 0.25, 1)
    love.graphics.print(string.format("EVAC  %.1fs", world.evacTimer), x + 160, y + 36)
  end

  local cd = math.max(0, p.dashCd)
  if cd > 0 then
    love.graphics.setColor(1, 0.8, 0.3, 0.9)
    love.graphics.print(string.format("DASH CD %.1fs", cd), x + 240, y + 2)
  end

  if world.msgT > 0 and world.msg ~= "" then
    love.graphics.setColor(0.06, 0.08, 0.12, 0.82)
    local w, h = love.graphics.getDimensions()
    love.graphics.rectangle("fill", w * 0.5 - 320, h - 120, 640, 56, 8, 8)
    love.graphics.setColor(0.75, 0.9, 1, 1)
    love.graphics.printf(world.msg, w * 0.5 - 300, h - 108, 600, "center")
  end
  love.graphics.setColor(1, 1, 1, 1)
end

function UI.drawMenu(title, subtitle)
  local w, h = love.graphics.getDimensions()
  UI.drawBackground()
  love.graphics.setColor(0.08, 0.12, 0.18, 0.75)
  love.graphics.rectangle("fill", w * 0.5 - 280, h * 0.5 - 160, 560, 320, 16, 16)
  love.graphics.setColor(0.4, 0.75, 1, 0.7)
  love.graphics.rectangle("line", w * 0.5 - 280, h * 0.5 - 160, 560, 320, 16, 16)
  love.graphics.setColor(0.9, 0.95, 1, 1)
  love.graphics.printf(title, 0, h * 0.5 - 120, w, "center")
  love.graphics.setColor(0.65, 0.75, 0.88, 1)
  love.graphics.printf(subtitle, w * 0.5 - 260, h * 0.5 - 40, 520, "center")
  love.graphics.setColor(0.5, 1, 0.75, 1)
  love.graphics.printf("ENTER — Begin    ESC — Quit\nTAB — How to play", 0, h * 0.5 + 60, w, "center")
  love.graphics.setColor(1, 1, 1, 1)
end

function UI.drawOverlay(text, hint)
  local w, h = love.graphics.getDimensions()
  love.graphics.setColor(0.02, 0.04, 0.08, 0.65)
  love.graphics.rectangle("fill", 0, 0, w, h)
  love.graphics.setColor(0.95, 0.97, 1, 1)
  love.graphics.printf(text, 0, h * 0.42, w, "center")
  love.graphics.setColor(0.65, 0.78, 0.9, 1)
  love.graphics.printf(hint or "", 0, h * 0.52, w, "center")
  love.graphics.setColor(1, 1, 1, 1)
end

return UI
l