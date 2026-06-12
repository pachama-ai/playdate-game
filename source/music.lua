-- music.lua: space atmosphere sound design

local sound <const> = playdate.sound
local sine  = sound.kWaveSine
local tri   = sound.kWaveTriangle
local sqr   = sound.kWaveSquare
local noise = sound.kWaveNoise

local coreSynth  = sound.synth.new(sine)
local droneSynth = sound.synth.new(tri)
local clickSynth = sound.synth.new(sqr)
local noiseSynth = sound.synth.new(noise)

local pulseTimer  = 0

function updateMusic(dt, playerRing, totalRings)
    pulseTimer = pulseTimer + dt
    local pulseInterval = 1.2 - playerRing * 0.1
    if pulseTimer >= pulseInterval then
        pulseTimer = 0
        local vol = 0.08 + playerRing * 0.02
        coreSynth:playNote(30 + playerRing * 5, 0.08, vol)
        coreSynth:playNote(1200 + math.random() * 400, 0.15, vol * 0.3)
        noiseSynth:playNote(3000, 0.05, vol * 0.15)
    end
    if S.enemies then
        local danger = 0
        for _, e in ipairs(S.enemies) do
            if not e.spawning and math.abs(e.ring - playerRing) <= 1 then danger = 1 end
        end
        if #S.enemies > 8 then danger = 2 end
        if danger >= 1 then
            droneSynth:playNote(65 + danger * 15, dt * 2, 0.04 + danger * 0.02)
        end
    end
end

function onBridgeCross()
    noiseSynth:playNote(100, 0.08, 0.06)
    clickSynth:playNote(400, 0.04, 0.04)
end
function sfxImplode()
    coreSynth:playNote(35, 2.0, 0.3)
    noiseSynth:playNote(40, 1.0, 0.2)
end
