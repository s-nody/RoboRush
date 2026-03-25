-- Runtime-generated sprite sheets (course: sprite sheet + quads + animation)

local sprites = {}

local function px(img, x, y, r, g, b, a)
  if x >= 0 and y >= 0 and x < img:getWidth() and y < img:getHeight() then
    img:setPixel(x, y, r, g, b, a or 1)
  end
end

local function rect(img, x0, y0, x1, y1, r, g, b, a)
  for y = y0, y1 do
    for x = x0, x1 do
      px(img, x, y, r, g, b, a)
    end
  end
end

local function drawBot(img, cx, tintR, tintG, tintB, eyeBright)
  local w, h = 32, 32
  local ox = cx - w / 2
  local oy = 0
  rect(img, ox + 6, oy + 8, ox + 25, oy + 26, tintR * 0.25, tintG * 0.35, tintB * 0.5)
  rect(img, ox + 8, oy + 10, ox + 23, oy + 24, tintR, tintG, tintB)
  rect(img, ox + 10, oy + 14, ox + 14, oy + 18, eyeBright, eyeBright * 0.95, 1)
  rect(img, ox + 18, oy + 14, ox + 22, oy + 18, eyeBright, eyeBright * 0.95, 1)
  rect(img, ox + 12, oy + 26, ox + 19, oy + 30, 0.35, 0.38, 0.42)
end

function sprites.load()
  local pw, ph = 128, 32
  local pdata = love.image.newImageData(pw, ph)
  for y = 0, ph - 1 do
    for x = 0, pw - 1 do
      pdata:setPixel(x, y, 0.06, 0.08, 0.12, 0)
    end
  end
  for f = 0, 3 do
    local shift = (f - 1.5) * 1.2
    drawBot(pdata, 16 + f * 32 + shift, 0.45, 0.82, 0.95, 0.85)
  end
  sprites.playerSheet = love.graphics.newImage(pdata)
  sprites.playerSheet:setFilter("nearest", "nearest")
  sprites.playerQuads = {}
  for i = 0, 3 do
    sprites.playerQuads[i + 1] = love.graphics.newQuad(i * 32, 0, 32, 32, pw, ph)
  end

  local ew, eh = 64, 32
  local edata = love.image.newImageData(ew, eh)
  for y = 0, eh - 1 do
    for x = 0, ew - 1 do
      edata:setPixel(x, y, 0.05, 0.05, 0.08, 0)
    end
  end
  drawBot(edata, 16, 0.95, 0.45, 0.35, 1)
  drawBot(edata, 48, 0.55, 0.35, 0.95, 0.75)
  sprites.enemySheet = love.graphics.newImage(edata)
  sprites.enemySheet:setFilter("nearest", "nearest")
  sprites.patrolQuad = love.graphics.newQuad(0, 0, 32, 32, ew, eh)
  sprites.hunterQuad = love.graphics.newQuad(32, 0, 32, 32, ew, eh)

  local cw, ch = 16, 16
  local cdata = love.image.newImageData(cw, ch)
  rect(cdata, 2, 2, 13, 13, 0.2, 0.95, 0.55)
  rect(cdata, 4, 4, 11, 11, 0.85, 1, 0.9)
  sprites.cellImg = love.graphics.newImage(cdata)
  sprites.cellImg:setFilter("nearest", "nearest")

  local nw, nh = 24, 24
  local ndata = love.image.newImageData(nw, nh)
  rect(ndata, 2, 2, 21, 21, 0.25, 0.3, 0.4)
  rect(ndata, 5, 5, 18, 18, 0.95, 0.75, 0.2)
  rect(ndata, 8, 9, 15, 14, 1, 0.95, 0.5)
  sprites.nodeImg = love.graphics.newImage(ndata)
  sprites.nodeImg:setFilter("nearest", "nearest")
end

return sprites
