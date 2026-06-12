-- sfx.lua: sound effects

local sound <const> = playdate.sound
local synth  = sound.synth.new(sound.kWaveSquare)
local synth2 = sound.synth.new(sound.kWaveNoise)

function sfxBridge()
    synth:playNote(660, 0.05, 0.3)
end
function sfxHit()
    synth2:playNote(80, 0.08, 0.4)
end
function sfxCenter()
    synth:playNote(880, 0.06, 0.3)
end
function sfxEnemyCollide()
    synth:playNote(440, 0.04, 0.2)
end
