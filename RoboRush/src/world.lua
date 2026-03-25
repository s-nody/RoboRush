local C = require("src.constants")
local playerMod = require("src.player")
local col = require("src.collision")
local roomMod = require("src.room")
local enemyMod = require("src.enemy")
local proj = require("src.projectiles")
local audio = require("src.audio")

local W = {}

function W.new()
  return {
    player = playerMod.create(),
    bullets = {},
    room = nil,
    roomIndex = 1,
    elapsed = 0,
    nodesRepaired = 0,
    evacTimer = nil,
    evacSpawnAcc = 0,
    msg = "",
    msgT = 0,
    shake = 0,
    rng = nil,
  }
end

function W.initRun(world)
  math.randomseed(os.time())
  world.rng = math.random
  world.roomIndex = 1
  world.elapsed = 0
  world.nodesRepaired = 0
  world.evacTimer = nil
  world.evacSpawnAcc = 0
  world.bullets = {}
  world.msg = "Restore power nodes. WASD move · Space dash · LMB shoot · E repair / collect"
  world.msgT = 5
  world.shake = 0
  playerMod.reset(world.player, 200, 200)
  world.room = roomMod.generate(world.roomIndex, world.rng, false)
  W.teleportToSpawn(world)
end

function W.teleportToSpawn(world)
  local r = world.room
  world.player.x = r.spawnX
  world.player.y = r.spawnY
  world.player.vx = 0
  world.player.vy = 0
end

function W.difficultySpeedMult(world)
  return 1 + world.roomIndex * 0.12 + world.elapsed * 0.02
end

function W.detectMult(world)
  return 1 + world.roomIndex * 0.08
end

function W.update(world, dt, input, mx, my, onVictory, onGameOver)
  world.elapsed = world.elapsed + dt
  if world.msgT > 0 then
    world.msgT = world.msgT - dt
  end
  if world.shake > 0 then
    world.shake = world.shake - dt * 2.5
  end

  local r = world.room
  local b = r.bounds

  playerMod.update(world.player, dt, input, b.minX, b.minY, b.maxX, b.maxY)

  if world.evacTimer then
    world.evacTimer = world.evacTimer - dt
    world.evacSpawnAcc = world.evacSpawnAcc + dt
    if world.evacSpawnAcc > 2.8 then
      world.evacSpawnAcc = 0
      r.enemies[#r.enemies + 1] = enemyMod.createHunter(world.rng, b, world.roomIndex + 4)
    end
    if world.evacTimer <= 0 then
      world.evacTimer = nil
      onVictory()
      return
    end
  end

  local ctx = {
    bounds = b,
    walls = r.walls,
    px = world.player.x,
    py = world.player.y,
    pw = world.player.w,
    ph = world.player.h,
    difficultySpeedMult = W.difficultySpeedMult(world),
    detectMult = W.detectMult(world),
    elapsed = world.elapsed,
  }

  for _, e in ipairs(r.enemies) do
    if e.hp > 0 then
      enemyMod.update(e, dt, ctx)
      if col.aabb(world.player.x, world.player.y, world.player.w, world.player.h, e.x, e.y, e.w, e.h) then
        if playerMod.takeDamage(world.player, 12, e.x, e.y, e.w, e.h) then
          audio.play(audio.sfx_damage)
          world.shake = 0.35
        end
      end
    end
  end

  proj.update(world.bullets, dt, b, r.walls)
  for bi = #world.bullets, 1, -1 do
    local bullet = world.bullets[bi]
    for _, e in ipairs(r.enemies) do
      if e.hp > 0 and col.aabb(bullet.x, bullet.y, bullet.w, bullet.h, e.x, e.y, e.w, e.h) then
        e.hp = e.hp - C.BULLET_DAMAGE
        audio.play(audio.sfx_hit)
        table.remove(world.bullets, bi)
        if e.hp <= 0 then
          world.player.score = world.player.score + (e.kind == "hunter" and 150 or 75)
        end
        break
      end
    end
  end

  for _, cell in ipairs(r.cells) do
    if cell.alive and col.aabb(world.player.x, world.player.y, world.player.w, world.player.h, cell.x, cell.y, cell.w, cell.h) then
      cell.alive = false
      world.player.energy = math.min(world.player.maxEnergy, world.player.energy + 22)
      world.player.score = world.player.score + 25
      audio.play(audio.sfx_collect)
    end
  end

  local pcx = world.player.x + world.player.w / 2
  local pcy = world.player.y + world.player.h / 2
  local n = r.node
  if input.interact and not n.repaired then
    if col.aabb(world.player.x - 6, world.player.y - 6, world.player.w + 12, world.player.h + 12, n.x - 8, n.y - 8, n.w + 16, n.h + 16) then
      n.repaired = true
      r.door.locked = false
      world.nodesRepaired = world.nodesRepaired + 1
      world.player.score = world.player.score + 200
      audio.play(audio.sfx_node)
      world.msg = "Power routed. Door unlocked — reach the exit field."
      world.msgT = 3.5
      if world.nodesRepaired >= C.NODES_TO_STABILIZE and not world.evacTimer then
        world.evacTimer = C.EVAC_DURATION
        r.door.locked = true
        world.msg = "FACILITY STABILIZED — SURVIVE EVACUATION (" .. tostring(C.EVAC_DURATION) .. "s)"
        world.msgT = 4
      end
    end
  end

  if not r.door.locked and not world.evacTimer then
    local d = r.door
    if col.aabb(world.player.x, world.player.y, world.player.w, world.player.h, d.x, d.y, d.w, d.h) then
      world.roomIndex = world.roomIndex + 1
      world.room = roomMod.generate(world.roomIndex, world.rng, false)
      W.teleportToSpawn(world)
      world.bullets = {}
      world.msg = "Sector " .. tostring(world.roomIndex) .. " — threats scaling."
      world.msgT = 2.2
    end
  end

  if input.fire and playerMod.canShoot(world.player) then
    local dx = mx - pcx
    local dy = my - pcy
    playerMod.applyShootCost(world.player)
    proj.spawn(world.bullets, pcx - 5, pcy - 5, dx, dy)
    audio.play(audio.sfx_shoot)
  end

  if input.dash then
    if playerMod.tryDash(world.player, input) then
      audio.play(audio.sfx_dash)
    end
  end

  if world.player.hp <= 0 then
    onGameOver()
  end
end

return W
