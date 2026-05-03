import "CoreLibs/graphics"

local gfx  <const> = playdate.graphics
local math <const> = math

local cx, cy = 200, 120

local RINGS = {
    { mid=100, inner=94,  outer=106, arcW=360 },
    { mid=74,  inner=66,  outer=82,  arcW=90,  bOff={8,14},  rot={ dir= 1, speed=13, pauseLen=0.75, startAngle=0  } },
    { mid=48,  inner=45,  outer=51,  arcW=360 },
    { mid=22,  inner=17,  outer=27,  arcW=90,  bOff={28,35}, rot={ dir=-1, speed=12, pauseLen=0.60, startAngle=90 } },
}
local RING_COUNT  = #RINGS
local SLIDING_GAP = 2   -- gap index with animated open/close bridges
local CENTER_R    = 10  -- radius of the central hole

local zoom       = 1.0
local zoomTarget = 1.0
local ZOOM_TABLE = {}
for i = 1, RING_COUNT do
    ZOOM_TABLE[i] = 1.0 + (i - 1) / (RING_COUNT - 1) * 2.0
end

local angles   = {}
local ringArcs = {}

local bridgeStates     = {}
local BRIDGE_OPEN_DUR  = 2.5
local BRIDGE_CLOSE_T   = 0.4
local BRIDGE_CLOSED_DUR= 1.8
local BRIDGE_OPEN_T    = 0.4
local BRIDGE_WARN      = 0.38

local bridgeModes = {}

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

local enemyParticles = {}
local ringDeltas = {}
local ppx        = 0
local ppy    = 0

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

local function clampToRingArc(ring, angleDeg)
    local function clamp(angle, arcStart, arcSweep)
        if arcSweep >= 360 then return angle % 360 end
        if ((angle - arcStart) % 360) <= arcSweep then return angle % 360 end
        local lo = arcStart % 360
        local hi = (arcStart + arcSweep) % 360
        if angleDist(angle, lo) <= angleDist(angle, hi) then return lo else return hi end
    end
    local r = RINGS[ring]
    if r.arcW < 360 then
        local hw     = r.arcW * 0.5
        local driver = angles[ring - 1]
        local a1     = driver % 360
        local a2     = (driver + 180) % 360
        local center = (angleDist(angleDeg, a1) <= angleDist(angleDeg, a2)) and a1 or a2
        return clamp(angleDeg, center - hw, r.arcW)
    else
        local parc = ringArcs[ring]
        return clamp(angleDeg, parc[1], parc[2])
    end
end

local function getBridgeAngles(gapIdx)
    local outerRing = RINGS[gapIdx]
    if outerRing.arcW >= 360 then
        -- Full-circle outer ring: 2 bridges at the rotation-driver angle ±180°
        return { angles[gapIdx] % 360, (angles[gapIdx] + 180) % 360 }
    else
        -- Arc outer ring: ring gapIdx tracks angles[gapIdx-1]
        local driver = angles[gapIdx - 1]
        local hw     = outerRing.arcW * 0.5
        local o1     = outerRing.bOff[1]
        local o2     = outerRing.bOff[2]
        if gapIdx == SLIDING_GAP then
            -- 4 bridges (2 per arc segment, one near each end)
            return {
                (driver - hw + o1) % 360,
                (driver + hw - o2) % 360,
                (driver + 180 - hw + o1) % 360,
                (driver + 180 + hw - o2) % 360,
            }
        else
            -- 2 bridges (one per arc segment, at the inner end)
            return {
                (driver + hw - o1) % 360,
                (driver + 180 + hw - o2) % 360,
            }
        end
    end
end

local function nearBridge(gapIdx, angleDeg, tol)
    tol = tol or BRIDGE_HALF
    local bridges = getBridgeAngles(gapIdx)
    if gapIdx == SLIDING_GAP then
        for j, ba in ipairs(bridges) do
            local bs = bridgeStates[j]
            local isOpen = (not bs) or (bs.state == 'open')
            if isOpen and angleDist(angleDeg, ba) <= tol then return true, ba end
        end
    else
        for _, ba in ipairs(bridges) do
            if angleDist(angleDeg, ba) <= tol then return true, ba end
        end
    end
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

local function drawRing(innerR, outerR, arcStart, arcSweep)
    arcStart = arcStart or 0
    arcSweep = arcSweep or 360
    if arcSweep >= 359 then
        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(cx, cy, sc(outerR))
        fillCircleWithBg(sc(innerR))
        return
    end
    local steps = math.max(24, math.ceil(arcSweep / 3))
    local da    = arcSweep / steps
    local oi    = sc(innerR)
    local oo    = sc(outerR)
    gfx.setColor(gfx.kColorBlack)
    for i = 0, steps-1 do
        local a1  = math.rad(arcStart + i*da)
        local a2  = math.rad(arcStart + (i+1)*da)
        local x1o = cx + oo*math.sin(a1); local y1o = cy - oo*math.cos(a1)
        local x2o = cx + oo*math.sin(a2); local y2o = cy - oo*math.cos(a2)
        local x1i = cx + oi*math.sin(a1); local y1i = cy - oi*math.cos(a1)
        local x2i = cx + oi*math.sin(a2); local y2i = cy - oi*math.cos(a2)
        gfx.fillPolygon(math.floor(x1o), math.floor(y1o),
                        math.floor(x2o), math.floor(y2o),
                        math.floor(x2i), math.floor(y2i),
                        math.floor(x1i), math.floor(y1i))
    end
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
    local nowMs = playdate.getCurrentTimeMilliseconds()

    -- Draw all rings
    for i = 1, RING_COUNT do
        local r = RINGS[i]
        if r.arcW >= 360 then
            drawRing(r.inner, r.outer)
        else
            local ra = angles[i - 1] - r.arcW * 0.5
            drawRing(r.inner, r.outer, ra,       r.arcW)
            drawRing(r.inner, r.outer, ra + 180, r.arcW)
        end
    end

    -- Draw bridges for every gap (gaps 1 .. RING_COUNT)
    for g = 1, RING_COUNT do
        local bGM, bHL, bHW
        if g < RING_COUNT then
            local ri = RINGS[g]
            local ro = RINGS[g + 1]
            bGM = (ri.inner + ro.outer) * 0.5
            bHL = (ri.inner - ro.outer) * 0.5 + 4
            bHW = math.min((ri.outer - ri.inner) * 0.5,
                           (ro.outer - ro.inner) * 0.5)
        else
            -- Innermost gap: between ring RING_COUNT and the centre circle
            local ri = RINGS[RING_COUNT]
            bGM = (ri.inner + CENTER_R) * 0.5
            bHL = (ri.inner - CENTER_R) * 0.5 + 4
            bHW = 2
        end

        local bridges = getBridgeAngles(g)
        if g == SLIDING_GAP then
            for j, ba in ipairs(bridges) do
                local bs = bridgeStates[j]
                if bs then
                    -- MIN_T ensures the stub always protrudes 5 units into the gap
                    -- formula: inner_end = bGM + bHL*(1-2t); we need it < ri.inner
                    -- bHL = gapHalf + 4 (overlap), so MIN_T = (4+stubSize)/(2*bHL)
                    local MIN_T    = (4 + 5) / (2 * bHL)
                    local effT     = math.max(bs.t, MIN_T)
                    local flicker  = (bs.state == 'open' and bs.timer <= BRIDGE_WARN)
                        and (math.floor(nowMs / 80) % 3 == 0)
                    if not flicker then
                        local visLen   = bHL * effT
                        local midShift = bHL * (1 - effT)
                        drawBridgeShape(ba, bGM + midShift, visLen, bHW)
                    end
                else
                    drawBridgeShape(ba, bGM, bHL, bHW)
                end
            end
        else
            for _, ba in ipairs(bridges) do
                drawBridgeShape(ba, bGM, bHL, bHW)
            end
        end
    end

    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(cx, cy, math.max(2, sc(CENTER_R)))
end

local function entityPos(ring, angle)
    local r   = sc(RINGS[ring].mid)
    local rad = math.rad(angle)
    return cx + r * math.sin(rad), cy - r * math.cos(rad)
end

local function entityPosOnGap(gapIdx, t, angle)
    local r1  = sc(RINGS[gapIdx].mid)
    local r2  = sc(RINGS[gapIdx + 1].mid)
    local r   = r1 + (r2 - r1) * t
    local rad = math.rad(angle)
    return cx + r * math.sin(rad), cy - r * math.cos(rad)
end

local function drawEntityCircle(px, py, radius)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(math.floor(px), math.floor(py), radius)
end

local function drawPlayer()
    local px, py
    if transiting then
        local r1  = sc(RINGS[playerRing].mid)
        local to  = math.max(1, math.min(RING_COUNT, playerRing + transDir))
        local r2  = sc(RINGS[to].mid)
        local r   = r1 + (r2 - r1) * transT
        local a   = math.rad(transAngle)
        px = cx + r * math.sin(a)
        py = cy - r * math.cos(a)
    else
        px, py = entityPos(playerRing, playerAngle)
    end
    local ipx = math.floor(px)
    local ipy = math.floor(py)
    -- Eyeball (white sclera)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(ipx, ipy, 5)
    -- Pupil
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(ipx, ipy, 2)
    -- Cute shine dot
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(ipx + 1, ipy - 2, 1, 1)
    -- Tiny eyelashes (top arc)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(ipx - 3, ipy - 4, ipx - 4, ipy - 5)
    gfx.drawLine(ipx,     ipy - 5, ipx,     ipy - 6)
    gfx.drawLine(ipx + 3, ipy - 4, ipx + 4, ipy - 5)
end

local function drawTriangleEnemy(px, py, angle, alpha)
    alpha = alpha or 1.0
    if alpha <= 0 then return end
    local rad = math.rad(angle)
    local dx = -math.sin(rad);  local dy =  math.cos(rad)
    local tx =  math.cos(rad);  local ty =  math.sin(rad)
    local sz = 5
    local tipX = math.floor(px + dx*sz); local tipY = math.floor(py + dy*sz)
    local b1X  = math.floor(px - dx*sz + tx*sz); local b1Y = math.floor(py - dy*sz + ty*sz)
    local b2X  = math.floor(px - dx*sz - tx*sz); local b2Y = math.floor(py - dy*sz - ty*sz)
    gfx.setColor(gfx.kColorWhite)
    if alpha > 0.5 then
        gfx.fillPolygon(tipX, tipY, b1X, b1Y, b2X, b2Y)
    else
        gfx.drawLine(tipX, tipY, b1X, b1Y)
        gfx.drawLine(b1X, b1Y, b2X, b2Y)
        gfx.drawLine(b2X, b2Y, tipX, tipY)
    end
end

local function drawEnemies()
    for _, p in ipairs(enemyParticles) do
        local t  = p.life / TRAIL_LIFE
        local sz = (t > 0.66) and 3 or (t > 0.33) and 2 or 1
        local hf = math.floor(sz / 2)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(math.floor(p.x) - hf, math.floor(p.y) - hf, sz, sz)
    end
    for _, e in ipairs(enemies) do
        if e.escaping then
            local px, py = entityPos(1, e.escapeAngle)
            drawTriangleEnemy(px, py, e.escapeAngle, 1.0 - e.escapeT)
        elseif e.onGap then
            local px, py = entityPosOnGap(e.gapDir, e.gapT, e.gapAngle)
            drawTriangleEnemy(px, py, e.gapAngle, 1.0)
        else
            local px, py = entityPos(e.ring, e.angle)
            drawTriangleEnemy(px, py, e.angle, 1.0)
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

local function setupBridgeModes(lvl)
    local lm = 1.0 + (lvl - 1) * 0.2
    bridgeModes = {}
    for i = 1, RING_COUNT do
        -- angles[i] drives the arc ring at index i+1 (if it exists and is an arc ring)
        local inner = RINGS[i + 1]
        if inner and inner.arcW < 360 and inner.rot then
            local cfg = inner.rot
            bridgeModes[i] = {
                type='rotate', dir=cfg.dir, speed=cfg.speed * lm,
                pauseEvery=math.max(2.5, 6.0 / lm), pauseLen=cfg.pauseLen,
                t=0, paused=false, pauseT=0,
            }
        else
            bridgeModes[i] = {
                type='rotate', dir=0, speed=0, pauseEvery=99, pauseLen=0,
                t=0, paused=false, pauseT=0,
            }
        end
    end
end

local function setupLevel(lvl)
    SPAWN_INTERVAL = math.max(1.5, 3.5 - (lvl - 1) * 0.4)
    enemies       = {}
    spawnTimer    = 1.5
    transiting    = false
    zoom          = 1.0
    zoomTarget    = 1.0
    aBufTimer     = 0
    bBufTimer     = 0
    particles      = {}
    playerHistory  = {}
    shatterPieces  = {}
    enemyParticles = {}

    -- Initialise angles: all zero, then apply per-arc-ring start angles
    angles = {}
    for i = 1, RING_COUNT do angles[i] = 0 end
    for r = 2, RING_COUNT do
        if RINGS[r].rot and RINGS[r].rot.startAngle then
            angles[r - 1] = RINGS[r].rot.startAngle
        end
    end

    -- Init ring arcs (full-circle rings may be restricted at higher levels)
    ringArcs = {}
    for i = 1, RING_COUNT do ringArcs[i] = {0, 360} end
    if lvl >= 2 then ringArcs[1] = {45, 270} end
    if lvl >= 3 then ringArcs[2] = {0,  180} end

    playerRing  = 1
    playerAngle = (ringArcs[1][1] + ringArcs[1][2] * 0.5) % 360

    -- Stagger bridge states for the SLIDING_GAP
    local nBridges   = #getBridgeAngles(SLIDING_GAP)
    local totalCycle = BRIDGE_OPEN_DUR + BRIDGE_CLOSE_T + BRIDGE_CLOSED_DUR + BRIDGE_OPEN_T
    bridgeStates = {}
    for j = 1, nBridges do
        local off = (j - 1) / nBridges * totalCycle
        local st, ti, tv
        if off < BRIDGE_OPEN_DUR then
            st='open';    ti=BRIDGE_OPEN_DUR-off;                         tv=1.0
        elseif off < BRIDGE_OPEN_DUR+BRIDGE_CLOSE_T then
            ti=BRIDGE_CLOSE_T-(off-BRIDGE_OPEN_DUR)
            st='closing'; tv=ti/BRIDGE_CLOSE_T
        elseif off < BRIDGE_OPEN_DUR+BRIDGE_CLOSE_T+BRIDGE_CLOSED_DUR then
            st='closed';  ti=BRIDGE_CLOSED_DUR-(off-BRIDGE_OPEN_DUR-BRIDGE_CLOSE_T); tv=0.0
        else
            local op=off-BRIDGE_OPEN_DUR-BRIDGE_CLOSE_T-BRIDGE_CLOSED_DUR
            ti=BRIDGE_OPEN_T-op
            st='opening'; tv=1.0-ti/BRIDGE_OPEN_T
        end
        bridgeStates[j] = { state=st, timer=ti, t=tv }
    end
    setupBridgeModes(lvl)
end

local function resetGame()
    level = 1
    setupLevel(level)
    gameState = STATE_PLAY
end

resetGame()
local lastMs = playdate.getCurrentTimeMilliseconds()

local function updateBridges(dt)
    local oldAngles = {}
    for i = 1, RING_COUNT do oldAngles[i] = angles[i] end

    for i = 1, RING_COUNT do
        local m = bridgeModes[i]
        if m.paused then
            m.pauseT = m.pauseT + dt
            if m.pauseT >= m.pauseLen then
                m.paused = false; m.pauseT = 0
            end
        elseif m.type == 'rotate' then
            angles[i] = (angles[i] + m.dir * m.speed * dt) % 360
            m.t       = m.t + dt
            if m.t >= m.pauseEvery then m.paused = true; m.t = 0 end
        end
    end

    -- Compute per-slot angular deltas for this frame
    for i = 1, RING_COUNT do
        ringDeltas[i] = ((angles[i] - oldAngles[i] + 180) % 360) - 180
    end

    -- Carry the player with its ring if it is an arc ring (tracks angles[ring-1])
    if not transiting then
        if RINGS[playerRing].arcW < 360 then
            playerAngle = (playerAngle + ringDeltas[playerRing - 1]) % 360
        end
    end

    -- Carry enemies with their ring
    for _, e in ipairs(enemies) do
        if not e.onGap and not e.escaping then
            if RINGS[e.ring].arcW < 360 then
                e.angle = clampToRingArc(e.ring, (e.angle + ringDeltas[e.ring - 1]) % 360)
            end
        end
    end

    for _, bs in ipairs(bridgeStates) do
        if bs.state == 'open' then
            bs.timer = bs.timer - dt
            if bs.timer <= 0 then bs.state='closing'; bs.timer=BRIDGE_CLOSE_T end
        elseif bs.state == 'closing' then
            bs.timer = bs.timer - dt
            bs.t     = math.max(0, bs.timer / BRIDGE_CLOSE_T)
            if bs.timer <= 0 then bs.state='closed'; bs.t=0; bs.timer=BRIDGE_CLOSED_DUR end
        elseif bs.state == 'closed' then
            bs.timer = bs.timer - dt
            if bs.timer <= 0 then bs.state='opening'; bs.timer=BRIDGE_OPEN_T end
        elseif bs.state == 'opening' then
            bs.timer = bs.timer - dt
            bs.t     = math.max(0, 1.0 - bs.timer / BRIDGE_OPEN_T)
            if bs.timer <= 0 then bs.state='open'; bs.t=1.0; bs.timer=BRIDGE_OPEN_DUR end
        end
    end
end

local function updatePlayer(dt)
    zoomTarget = ZOOM_TABLE[playerRing]
    zoom       = zoom + (zoomTarget - zoom) * dt * 5

    if playdate.buttonJustPressed(playdate.kButtonA) then aBufTimer = BUF_TIME end
    if playdate.buttonJustPressed(playdate.kButtonB) then bBufTimer = BUF_TIME end

    if not transiting then
        playerAngle = (playerAngle + playdate.getCrankChange()) % 360
        playerAngle = clampToRingArc(playerRing, playerAngle)

        if aBufTimer > 0 and playerRing <= RING_COUNT then
            if playerRing == RING_COUNT then
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

    if transiting then
        local r1 = sc(RINGS[playerRing].mid)
        local to = math.max(1, math.min(RING_COUNT, playerRing + transDir))
        local r2 = sc(RINGS[to].mid)
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
end

local function updateEnemies(dt)
    spawnTimer = spawnTimer - dt
    if spawnTimer <= 0 then
        spawnTimer = SPAWN_INTERVAL
        local outerArc    = RINGS[RING_COUNT]
        local driverAngle = angles[RING_COUNT - 1]
        local spawnOpts = {
            (driverAngle + outerArc.arcW * 0.5) % 360,
            (driverAngle + 180 + outerArc.arcW * 0.5) % 360,
        }
        local ba = spawnOpts[math.random(1, 2)]
        table.insert(enemies, {
            ring = RING_COUNT, angle = ba,
            onGap = false, gapDir = 0, gapAngle = ba, gapT = 0.0, gapIdx = 0,
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
            local g = e.gapIdx
            if g >= 1 then
                local driverIdx = (RINGS[g].arcW >= 360) and g or (g - 1)
                e.gapAngle = (e.gapAngle + ringDeltas[driverIdx]) % 360
            end
            e.gapT = e.gapT - dt * ENEMY_GAP_SPD
            if e.gapT <= 0.0 then
                e.onGap = false
                e.ring  = e.gapDir
                e.angle = clampToRingArc(e.gapDir, e.gapAngle)
                e.gapT  = 0.0
            end
        else
            local gapToExit = e.ring - 1
            if gapToExit < 1 then
                e.escaping    = true
                e.escapeT     = 0.0
                e.escapeAngle = e.angle
            else
                local candidates = getBridgeAngles(gapToExit)
                if gapToExit == SLIDING_GAP then
                    local open = {}
                    for j, ba in ipairs(candidates) do
                        local bs = bridgeStates[j]
                        if (not bs) or (bs.state == 'open') then
                            table.insert(open, ba)
                        end
                    end
                    candidates = open
                end
                local bestAng, bestDist = nil, 361
                for _, ba in ipairs(candidates) do
                    local d = angleDist(e.angle, ba)
                    if d < bestDist then bestDist = d; bestAng = ba end
                end
                if bestAng then
                    local diff = ((bestAng - e.angle + 180) % 360) - 180
                    local step = ENEMY_SPEED * dt
                    if math.abs(diff) <= step then
                        e.angle    = bestAng
                        e.onGap    = true
                        e.gapIdx   = gapToExit
                        e.gapDir   = gapToExit
                        e.gapAngle = bestAng
                        e.gapT     = 1.0
                    else
                        e.angle = (e.angle + (diff > 0 and step or -step)) % 360
                        e.angle = clampToRingArc(e.ring, e.angle)
                    end
                end
            end
        end
    end
end

local function updateCollision()
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
end

local function updateEnemyTrails(dt)
    for i = #enemyParticles, 1, -1 do
        enemyParticles[i].life = enemyParticles[i].life - dt
        if enemyParticles[i].life <= 0 then table.remove(enemyParticles, i) end
    end
    for _, e in ipairs(enemies) do
        if not e.escaping then
            local px, py
            if e.onGap then
                px, py = entityPosOnGap(e.gapDir, e.gapT, e.gapAngle)
            else
                px, py = entityPos(e.ring, e.angle)
            end
            table.insert(enemyParticles, {x=px, y=py, life=TRAIL_LIFE})
            if #enemyParticles > 60 then table.remove(enemyParticles, 1) end
        end
    end
end

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

    updateBridges(dt)
    updatePlayer(dt)
    if gameState ~= STATE_PLAY then return end
    updateEnemies(dt)
    updateEnemyTrails(dt)
    updateCollision()

    drawBoard()
    drawTrailParticles()
    drawEnemies()
    drawPlayer()

    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(2, 2, 24, 12)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawText('L' .. level, 4, 3)
end