local path = love.filesystem.getRequirePath()
love.filesystem.setRequirePath(path .. ";src/?.lua")

local C = require("src.constants")
local sprites = require("src.sprites")
local audio = require("src.audio")
local worldMod = require("src.world")
local UI = require("src.ui")


local state = "menu"
local world
local showHelp = false
local scale = 1
local tx, ty = 0, 0

local input = {
  left = false,
  right = false,
  up = false,
  down = false,
  fire = false,
  interact = false,
  dash = false,
}

local fireHeld = false
local interactPress = false
local dashPress = false

local function toGame(mx, my)
  return (mx - tx) / scale, (my - ty) / scale
end

function love.load()
  love.graphics.setDefaultFilter("linear", "linear")
  sprites.load()
  audio.load()
  world = worldMod.new()
  local w, h = love.graphics.getDimensions()
  scale = math.min(w / C.GAME_W, h / C.GAME_H)
  tx = (w - C.GAME_W * scale) * 0.5
  ty = (h - C.GAME_H * scale) * 0.5
end

function love.resize()
  local w, h = love.graphics.getDimensions()
  scale = math.min(w / C.GAME_W, h / C.GAME_H)
  tx = (w - C.GAME_W * scale) * 0.5
  ty = (h - C.GAME_H * scale) * 0.5
end

local function startGame()
  state = "play"
  showHelp = false
  audio.startMusic()
  worldMod.initRun(world)
end

function love.keypressed(key)
  if key == "escape" then
    if state == "play" then
      state = "pause"
    elseif state == "pause" then
      state = "play"
    elseif state == "menu" then
      love.event.quit()
    elseif state == "help" then
      showHelp = false
      state = "menu"
    elseif state == "gameover" or state == "victory" then
      state = "menu"
    end
    return
  end
  if state == "menu" then
    if key == "return" or key == "kpenter" then
      startGame()
    elseif key == "tab" then
      state = "help"
    end
    return
  end
  if state == "pause" and (key == "return" or key == "kpenter") then
    state = "play"
    return
  end
  if (state == "gameover" or state == "victory") and (key == "return" or key == "kpenter") then
    startGame()
    return
  end
  if key == "e" then
    interactPress = true
  end
  if key == "space" then
    dashPress = true
  end
end

function love.mousepressed(_, _, button)
  if button == 1 and state == "play" then
    fireHeld = true
  end
end

function love.mousereleased(_, _, button)
  if button == 1 then
    fireHeld = false
  end
end

function love.update(dt)
  if state ~= "play" then
    return
  end
  input.left = love.keyboard.isDown("a") or love.keyboard.isDown("left")
  input.right = love.keyboard.isDown("d") or love.keyboard.isDown("right")
  input.up = love.keyboard.isDown("w") or love.keyboard.isDown("up")
  input.down = love.keyboard.isDown("s") or love.keyboard.isDown("down")
  input.fire = fireHeld or love.mouse.isDown(1)
  input.interact = interactPress
  input.dash = dashPress
  interactPress = false
  dashPress = false

  local mx, my = love.mouse.getPosition()
  local gx, gy = toGame(mx, my)

  worldMod.update(world, dt, input, gx, gy, function()
    state = "victory"
    audio.stopMusic()
  end, function()
    state = "gameover"
    audio.stopMusic()
  end)
end

function love.draw()
  love.graphics.push()
  love.graphics.translate(tx, ty)
  love.graphics.scale(scale, scale)

  if state == "menu" then
    love.graphics.pop()
    UI.drawMenu(
      "ECLIPSE PROTOCOL",
      "Maintenance unit — restore power nodes, survive drones, evacuate when the station stabilizes."
    )
    return
  end

  if state == "help" then
    love.graphics.pop()
    local w, h = love.graphics.getDimensions()
    UI.drawMenu("HOW TO PLAY", "")
    love.graphics.setColor(0.75, 0.88, 1, 1)
    love.graphics.printf(
      "WASD — move\nSpace — dash (energy)\nMouse / LMB — aim & plasma bolts\nE — repair node when close\n"
        .. "Patrol drones sweep fixed paths. Hunters use FSM: patrol → chase → return.\n"
        .. "Repair "
        .. tostring(C.NODES_TO_STABILIZE)
        .. " nodes to trigger evacuation — survive the countdown to win.",
      w * 0.5 - 260,
      h * 0.5 - 10,
      520,
      "left"
    )
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("ESC — back", 0, h * 0.5 + 130, w, "center")
    return
  end

  local shakeX, shakeY = 0, 0
  if world.shake and world.shake > 0 then
    shakeX = (math.random() - 0.5) * 14 * world.shake
    shakeY = (math.random() - 0.5) * 14 * world.shake
  end
  love.graphics.translate(shakeX, shakeY)

  UI.drawBackground()
  if world.room then
    UI.drawRoom(world.room, world.evacTimer)
    UI.drawEnemies(world.room, sprites)
  end
  UI.drawPlayer(world.player, sprites)
  UI.drawBullets(world.bullets)
  UI.drawHUD(world)

  love.graphics.pop()

  if state == "pause" then
    UI.drawOverlay("PAUSED", "ENTER resume · ESC menu")
  elseif state == "gameover" then
    UI.drawOverlay(
      "SIGNAL LOST",
      "Score " .. tostring(math.floor(world.player.score)) .. " · ENTER restart · ESC menu"
    )
  elseif state == "victory" then
    UI.drawOverlay(
      "EVACUATION COMPLETE",
      "Score " .. tostring(math.floor(world.player.score)) .. " · Time " .. string.format("%.0fs", world.player.survivalTime) .. " · ENTER restart"
    )
  end
end
