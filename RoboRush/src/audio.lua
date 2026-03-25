-- Procedural SoundData (BGM loop + SFX) — no external files required

local audio = {}

local function sineTone(duration, freq, vol, sampleRate)
  sampleRate = sampleRate or 44100
  local n = math.floor(duration * sampleRate)
  local sd = love.sound.newSoundData(n, sampleRate, 16, 1)
  for i = 0, n - 1 do
    local t = i / sampleRate
    local env = math.min(1, i / (sampleRate * 0.02)) * math.min(1, (n - i) / (sampleRate * 0.04))
    sd:setSample(i, math.sin(t * freq * math.pi * 2) * vol * env)
  end
  return love.audio.newSource(sd, "static")
end

local function noiseBurst(duration, vol)
  local sampleRate = 44100
  local n = math.floor(duration * sampleRate)
  local sd = love.sound.newSoundData(n, sampleRate, 16, 1)
  math.randomseed(os.time())
  for i = 0, n - 1 do
    local env = (n - i) / n
    sd:setSample(i, (math.random() * 2 - 1) * vol * env)
  end
  return love.audio.newSource(sd, "static")
end

local function ambientLoop()
  local sampleRate = 22050
  local seconds = 2.4
  local n = math.floor(sampleRate * seconds)
  local sd = love.sound.newSoundData(n, sampleRate, 16, 1)
  for i = 0, n - 1 do
    local t = i / sampleRate
    local s = math.sin(t * 55 * math.pi * 2) * 0.05 + math.sin(t * 110 * math.pi * 2) * 0.03
    local pulse = 0.5 + 0.5 * math.sin(t * 2.1 * math.pi * 2)
    sd:setSample(i, s * pulse * 0.35)
  end
  local src = love.audio.newSource(sd, "static")
  src:setLooping(true)
  src:setVolume(0.35)
  return src
end

function audio.load()
  audio.sfx_hit = sineTone(0.08, 180, 0.45)
  audio.sfx_collect = sineTone(0.12, 660, 0.35)
  audio.sfx_dash = sineTone(0.06, 320, 0.4)
  audio.sfx_shoot = sineTone(0.04, 880, 0.25)
  audio.sfx_node = sineTone(0.2, 220, 0.3)
  audio.sfx_damage = noiseBurst(0.1, 0.2)
  audio.music = ambientLoop()
end

function audio.play(s)
  if s and s:isPlaying() then
    s:stop()
  end
  if s then
    s:play()
  end
end

function audio.startMusic()
  if audio.music and not audio.music:isPlaying() then
    audio.music:play()
  end
end

function audio.stopMusic()
  if audio.music then
    audio.music:stop()
  end
end

return audio
