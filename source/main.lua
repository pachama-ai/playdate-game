import "CoreLibs/graphics"

local gfx  <const> = playdate.graphics
local math <const> = math

local cx, cy = 200, 120

local RING_MID   = { 102, 75, 48, 21 }
local RING_INNER = {  95, 68, 41, 14 }
local RING_OUTER = { 110, 82, 55, 28 }

local zoom       = 1.0
local zoomTarget = 1.0
local ZOOM_TABLE = { 1.0, 1.45, 2.1, 3.0 }

local GAP_MID     = { 88, 61, 34, 7 }
local bridgeCount = { 4, 4, 4, 4 }
local angles      = { 0, 45, 22, 67 }

local bridgeModes = {
    { speed = 0.45,  pauseEvery = 5.0, pauseLen = 1.0, t = 0, paused = false, pauseT = 0 },
    { speed = -0.6,  pauseEvery = 7.0, pauseLen = 0.8, t = 0, paused = false, pauseT = 0 },
    { speed = 0.35,  pauseEvery = 4.5, pauseLen = 1.2, t = 0, paused = false, pauseT = 0 },
    { speed = -0.5,  pauseEvery = 6.0, pauseLen = 0.9, t = 0, paused = false, pauseT = 0 },
}

local BRIDGE_HALF      = 14
local BRIDGE_HALF_BACK = 22

local playerRing  = 1
local playerAngle = 45.0
local transiting  = false
local transDir    = 0
local transT      = 0.0
local transAngle  = 0.0
local TRANS_TIME  = 0.2

local enemies        = {}
local ENEMY_SPEED    = 48
local ENEMY_GAP_SPD  = 1.5
local spawnTimer     = 1.5
local SPAWN_INTERVAL = 3.5
local ESCAPE_TIME    = 0.45

local aBufTimer = 0.0
local bBufTimer = 0.0
local BUF_TIME  = 0.3

local STATE_PLAY    = 'play'
local STATE_DEAD    = 'dead'
local STATE_IMPLODE = 'implode'
local gameState  = STATE_PLAY
local deadTimer  = 0.0
local DEAD_HOLD  = 2.0
local implodeT   = 0.0
local IMPLODE_DUR = 1.2
local level      = 1

-- Particle trail & motion blur
local particles     = {}
local TRAIL_LIFE    = 0.25
local playerHistory = {}
local HISTORY_MAX   = 4

-- Shatter pieces on death
local shatterPieces = {}

local function sc(r) return r * zoom end

local function addTrailParticle(px, py)
    table.insert(particles, {x = px, y = py, life = TRAIL_LIFE})
    if #particles > 12 then table.remove(particles, 1) end
end

local function updateParticles(dt)
    for i = #particles, 1, -1 do
        particles[i].life = particles[i].life - dt
        if particles[i].life <= 0 then table.remove(particles, i) end
    end
end

local function drawTrailParticles()
    -- motion-blur ghosts: older positions drawn smaller
    local n = #playerHistory
    for i, h in ipairs(playerHistory) do
        local t  = i / n
        local sz = math.max(1, math.floor(t * 6 + 0.5))
        local hf = math.floor(sz / 2)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(math.floor(h.x) - hf, math.floor(h.y) - hf, sz, sz)
    end
    -- particle dots fading out
    for _, p in ipairs(particles) do
        local t  = p.life / TRAIL_LIFE
        local sz = (t > 0.66) and 3 or (t > 0.33) and 2 or 1
        local hf = math.floor(sz / 2)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(math.floor(p.x) - hf, math.floor(p.y) - hf, sz, sz)
    end
end

local function spawnShatter(px, py)
    shatterPieces = {}
    for i = 1, 12 do
        local angle = math.random() * math.pi * 2
        local speed = 25 + math.random() * 65
        local life  = 0.7 + math.random() * 0.7
        table.insert(shatterPieces, {
            x = px, y = py,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            life = life, maxLife = life,
            size = math.random(2, 4),
        })
    end
end

local function angleDist(a, b)
    return math.abs(((a - b + 180) % 360) - 180)
end

local function nearBridge(gapIdx, angleDeg, tol)
    tol = tol or BRIDGE_HALF
    local n    = bridgeCount[gapIdx]
    local base = angles[gapIdx]
    local best    = tol + 1
    local bestBa  = nil
    for i = 0, n-1 do
        local ba   = (base + i * (360/n)) % 360
        local diff = angleDist(angleDeg, ba)
        if diff < best then best = diff; bestBa = ba end
    end
    if bestBa and best <= tol then return true, bestBa end
    return false, nil
end

local function drawScanlineBg()
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 0, 400, 240)
    gfx.setColor(gfx.kColorBlack)
    for y = 0, 239, 2 do
        gfx.drawLine(0, y, 399, y)
    end
end

local function fillCircleWithBg(r)
    local ri = math.ceil(r)
    for dy = -ri, ri do
        local y = cy + dy
        if y >= 0 and y <= 239 then
            local sq = r*r - dy*dy
            if sq >= 0 then
                local chordX = math.floor(math.sqrt(sq))
                if y % 2 == 0 then
                    gfx.setColor(gfx.kColorBlack)
                else
                    gfx.setColor(gfx.kColorWhite)
                end
                gfx.drawLine(cx - chordX, y, cx + chordX, y)
            end
        end
    end
end

local function drawRing(innerR, outerR)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(cx, cy, sc(outerR))
    fillCircleWithBg(sc(innerR))
end

local function drawBridgeShape(angle_deg, midR, halfLen, halfW)
    local angle = math.rad(angle_deg)
    local r  = sc(midR)
    local bx = cx + r * math.sin(angle)
    local by = cy - r * math.cos(angle)
    local hh = halfLen * zoom
    local hw = halfW   * zoom
    local ca = math.cos(angle)
    local sa = math.sin(angle)
    local function rot(px, py)
        return bx + px*ca - py*sa,
               by + px*sa + py*ca
    end
    local x1,y1 = rot(-hw,-hh)
    local x2,y2 = rot( hw,-hh)
    local x3,y3 = rot( hw, hh)
    local x4,y4 = rot(-hw, hh)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillPolygon(x1,y1, x2,y2, x3,y3, x4,y4)
end

local function drawBoard()
    drawScanlineBg()
    for i = 1, 4 do
        drawRing(RING_INNER[i], RING_OUTER[i])
        local n    = bridgeCount[i]
        local hLen = (i == 4) and 4 or 7
        local hW   = (i == 4) and 5 or 6
        for j = 0, n-1 do
            drawBridgeShape(angles[i] + j*(360/n), GAP_MID[i], hLen, hW)
        end
    end
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(cx, cy, math.max(2, sc(10)))
end

local function entityPos(ring, angle)
    local r   = sc(RING_MID[ring])
    local rad = math.rad(angle)
    return cx + r * math.sin(rad), cy - r * math.cos(rad)
end

local function entityPosOnGap(gapIdx, t, angle)
    local r1  = sc(RING_MID[gapIdx])
    local r2  = sc(RING_MID[gapIdx + 1])
    local r   = r1 + (r2 - r1) * t
    local rad = math.rad(angle)
    return cx + r * math.sin(rad), cy - r * math.cos(rad)
end

local function drawPlayer()
    local px, py
    if transiting then
        local r1  = sc(RING_MID[playerRing])
        local to  = math.max(1, math.min(4, playerRing + transDir))
        local r2  = sc(RING_MID[to])
        local r   = r1 + (r2 - r1) * transT
        local a   = math.rad(transAngle)
        px = cx + r * math.sin(a)
        py = cy - r * math.cos(a)
    else
        px, py = entityPos(playerRing, playerAngle)
    end
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(math.floor(px-4), math.floor(py-4), 8, 8)
end

-- Enemy: small filled rectangle + tangential rays left & right (lens/streak shape like concept)
local function drawSpikyEnemy(px, py, angle, alpha)
    alpha = alpha or 1.0
    if alpha <= 0 then return end

    local rad = math.rad(angle)
    local odx =  math.sin(rad)   -- radial (outward from center)
    local ody = -math.cos(rad)
    local tdx = -ody              -- tangential (along ring)
    local tdy =  odx

    local bodyW  = 2   -- half-width of body (tangential)
    local bodyH  = 3   -- half-height of body (radial)
    local rayExt = 5   -- extra rows of rays beyond body top/bottom
    local maxRay = 9   -- max ray length at center row

    -- row skip for fade-out dither
    local rowSkip = 0
    if alpha < 0.35 then rowSkip = 3
    elseif alpha < 0.65 then rowSkip = 2
    end

    gfx.setColor(gfx.kColorWhite)

    -- rays (tangential lines) for each radial row, only outside the body
    local totalH = bodyH + rayExt
    for i = -totalH, totalH do
        if rowSkip == 0 or i % rowSkip == 0 then
            local t    = 1.0 - (math.abs(i) / (totalH + 1))
            local rLen = math.floor(maxRay * t * t)
            if rLen >= 1 then
                local bx     = px + odx * i
                local by_    = py + ody * i
                local startT = (math.abs(i) <= bodyH) and (bodyW + 1) or 1
                -- right ray
                gfx.drawLine(
                    math.floor(bx + tdx * startT),          math.floor(by_ + tdy * startT),
                    math.floor(bx + tdx * (startT + rLen)), math.floor(by_ + tdy * (startT + rLen)))
                -- left ray
                gfx.drawLine(
                    math.floor(bx - tdx * startT),          math.floor(by_ - tdy * startT),
                    math.floor(bx - tdx * (startT + rLen)), math.floor(by_ - tdy * (startT + rLen)))
            end
        end
    end

    -- solid body on top of rays
    for i = -bodyH, bodyH do
        if rowSkip == 0 or i % rowSkip == 0 then
            local bx  = px + odx * i
            local by_ = py + ody * i
            gfx.drawLine(
                math.floor(bx - tdx * bodyW), math.floor(by_ - tdy * bodyW),
                math.floor(bx + tdx * bodyW), math.floor(by_ + tdy * bodyW))
        end
    end
end

local function drawEnemies()
    for _, e in ipairs(enemies) do
        if e.escaping then
            -- fade out in place: scale goes 1→0, dithered
            local px, py = entityPos(1, e.escapeAngle)
            drawSpikyEnemy(px, py, e.escapeAngle, 1.0 - e.escapeT)
        elseif e.onGap then
            local px, py = entityPosOnGap(e.gapDir, e.gapT, e.gapAngle)
            drawSpikyEnemy(px, py, e.gapAngle, 1.0)
        else
            local px, py = entityPos(e.ring, e.angle)
            drawSpikyEnemy(px, py, e.angle, 1.0)
        end
    end
end

local function drawImplode(t)
    if t < 0.5 then
        drawBoard()
        drawPlayer()
        local lines = math.floor(t * 2 * 60)
        gfx.setColor(gfx.kColorBlack)
        for y = 0, lines do
            gfx.drawLine(0, y*4 % 240, 399, y*4 % 240)
        end
    else
        local alpha = (t - 0.5) * 2
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(0, 0, 400, 240)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(cx, cy, alpha * 210)
        gfx.setColor(gfx.kColorBlack)
        for y = 0, 239, 2 do
            gfx.drawLine(0, y, 399, y)
        end
    end
end

local function setupLevel(lvl)
    local lm = 1.0 + (lvl - 1) * 0.25
    bridgeModes[1].speed =  0.45 * lm
    bridgeModes[2].speed = -0.6  * lm
    bridgeModes[3].speed =  0.35 * lm
    bridgeModes[4].speed = -0.5  * lm
    for i = 1, 4 do
        bridgeModes[i].t      = 0
        bridgeModes[i].paused = false
        bridgeModes[i].pauseT = 0
    end
    SPAWN_INTERVAL = math.max(1.5, 3.5 - (lvl - 1) * 0.4)
    enemies     = {}
    spawnTimer  = 1.5
    playerRing  = 1
    playerAngle = 45
    transiting  = false
    zoom        = 1.0
    zoomTarget  = 1.0
    angles      = { 0, 45, 22, 67 }
    aBufTimer     = 0
    bBufTimer     = 0
    particles     = {}
    playerHistory = {}
    shatterPieces = {}
end

local function resetGame()
    level = 1
    setupLevel(level)
    gameState = STATE_PLAY
end

resetGame()
local lastMs = playdate.getCurrentTimeMilliseconds()

function playdate.update()
    local now = playdate.getCurrentTimeMilliseconds()
    local dt  = math.min((now - lastMs) / 1000.0, 0.05)
    lastMs    = now

    if gameState == STATE_IMPLODE then
        implodeT = implodeT + dt / IMPLODE_DUR
        if implodeT >= 1.0 then
            level     = level + 1
            setupLevel(level)
            gameState = STATE_PLAY
            implodeT  = 0.0
        else
            drawImplode(implodeT)
        end
        return
    end

    if gameState == STATE_DEAD then
        deadTimer = deadTimer + dt
        -- update shatter physics
        for i = #shatterPieces, 1, -1 do
            local p = shatterPieces[i]
            p.x    = p.x + p.vx * dt
            p.y    = p.y + p.vy * dt
            p.vy   = p.vy + 100 * dt
            p.life = p.life - dt
            if p.life <= 0 then table.remove(shatterPieces, i) end
        end
        if math.floor(deadTimer * 6) % 2 == 0 then
            drawBoard()
            drawEnemies()
            for _, p in ipairs(shatterPieces) do
                local t  = math.max(0, p.life / p.maxLife)
                local sz = math.max(1, math.floor(p.size * t + 0.5))
                local hf = math.floor(sz / 2)
                gfx.setColor(gfx.kColorWhite)
                gfx.fillRect(math.floor(p.x) - hf, math.floor(p.y) - hf, sz, sz)
            end
        else
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(0, 0, 400, 240)
        end
        if deadTimer >= DEAD_HOLD then
            resetGame()
        end
        return
    end

    for i = 1, 4 do
        local m = bridgeModes[i]
        if m.paused then
            m.pauseT = m.pauseT + dt
            if m.pauseT >= m.pauseLen then
                m.paused = false
                m.pauseT = 0
                m.speed  = -m.speed
            end
        else
            angles[i] = (angles[i] + m.speed) % 360
            m.t = m.t + dt
            if m.t >= m.pauseEvery then
                m.paused = true
                m.t      = 0
            end
        end
    end

    zoomTarget = ZOOM_TABLE[playerRing]
    zoom       = zoom + (zoomTarget - zoom) * dt * 5

    if playdate.buttonJustPressed(playdate.kButtonA) then aBufTimer = BUF_TIME end
    if playdate.buttonJustPressed(playdate.kButtonB) then bBufTimer = BUF_TIME end

    if not transiting then
        playerAngle = (playerAngle + playdate.getCrankChange()) % 360

        if aBufTimer > 0 and playerRing <= 4 then
            if playerRing == 4 then
                local ok, _ = nearBridge(4, playerAngle, BRIDGE_HALF)
                if ok then
                    gameState = STATE_IMPLODE
                    implodeT  = 0.0
                    aBufTimer = 0
                    return
                end
            else
                local ok, ba = nearBridge(playerRing, playerAngle, BRIDGE_HALF)
                if ok then
                    transiting = true; transDir = 1; transT = 0; transAngle = ba
                    aBufTimer  = 0
                end
            end
        end
        aBufTimer = math.max(0, aBufTimer - dt)

        if bBufTimer > 0 and playerRing > 1 then
            local ok, ba = nearBridge(playerRing - 1, playerAngle, BRIDGE_HALF_BACK)
            if ok then
                transiting = true; transDir = -1; transT = 0; transAngle = ba
                bBufTimer  = 0
            end
        end
        bBufTimer = math.max(0, bBufTimer - dt)
    else
        transT = transT + dt / TRANS_TIME
        if transT >= 1.0 then
            playerRing  = playerRing + transDir
            playerAngle = transAngle
            transiting  = false
            transT      = 1.0
        end
    end

    spawnTimer = spawnTimer - dt
    if spawnTimer <= 0 then
        spawnTimer = SPAWN_INTERVAL
        local n  = bridgeCount[4]
        local j  = math.random(0, n-1)
        local ba = (angles[4] + j*(360/n)) % 360
        table.insert(enemies, {
            ring = 4, angle = ba,
            onGap = false, gapDir = 0, gapAngle = ba, gapT = 0.0,
        })
    end

    for idx = #enemies, 1, -1 do
        local e = enemies[idx]
        if e.escaping then
            e.escapeT = e.escapeT + dt / ESCAPE_TIME
            if e.escapeT >= 1.0 then
                table.remove(enemies, idx)
            end
        elseif e.onGap then
            e.gapT = e.gapT - dt * ENEMY_GAP_SPD
            if e.gapT <= 0.0 then
                e.onGap = false
                e.ring  = e.gapDir
                e.angle = e.gapAngle
                e.gapT  = 0.0
            end
        else
            local gapToExit = e.ring - 1
            if gapToExit < 1 then
                e.escaping    = true
                e.escapeT     = 0.0
                e.escapeAngle = e.angle
            else
                local n       = bridgeCount[gapToExit]
                local best    = 360
                local bestAng = e.angle
                for j = 0, n-1 do
                    local ba = (angles[gapToExit] + j*(360/n)) % 360
                    local d  = angleDist(e.angle, ba)
                    if d < best then best = d; bestAng = ba end
                end
                local diff = ((bestAng - e.angle + 180) % 360) - 180
                local step = ENEMY_SPEED * dt
                if math.abs(diff) <= step then
                    e.angle    = bestAng
                    e.onGap    = true
                    e.gapDir   = gapToExit
                    e.gapAngle = bestAng
                    e.gapT     = 1.0
                else
                    e.angle = (e.angle + (diff > 0 and step or -step)) % 360
                end
            end
        end
    end

    local ppx, ppy
    if transiting then
        local r1 = sc(RING_MID[playerRing])
        local to = math.max(1, math.min(4, playerRing + transDir))
        local r2 = sc(RING_MID[to])
        local r  = r1 + (r2 - r1) * transT
        local a  = math.rad(transAngle)
        ppx = cx + r * math.sin(a)
        ppy = cy - r * math.cos(a)
    else
        ppx, ppy = entityPos(playerRing, playerAngle)
    end

    addTrailParticle(ppx, ppy)
    updateParticles(dt)
    table.insert(playerHistory, {x = ppx, y = ppy})
    if #playerHistory > HISTORY_MAX then table.remove(playerHistory, 1) end

    for _, e in ipairs(enemies) do
        if e.escaping then goto continue end
        local epx, epy
        if e.onGap then
            epx, epy = entityPosOnGap(e.gapDir, e.gapT, e.gapAngle)
        else
            epx, epy = entityPos(e.ring, e.angle)
        end
        if math.abs(ppx - epx) < 8 and math.abs(ppy - epy) < 8 then
            gameState     = STATE_DEAD
            deadTimer     = 0.0
            particles     = {}
            playerHistory = {}
            spawnShatter(ppx, ppy)
            break
        end
        ::continue::
    end

    drawBoard()
    drawTrailParticles()
    drawEnemies()
    drawPlayer()

    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(2, 2, 24, 12)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawText('L' .. level, 4, 3)
end