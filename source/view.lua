-- view.lua: all drawing functions (segment-based architecture)

import "CoreLibs/graphics"
import "gfxp"

local gfx  <const> = playdate.graphics
local math <const> = math
local gfxp <const> = GFXP

-- Hintergrund: dot-6i Pattern (in Image gebacken, kein aktives Pattern)
local abstractBg = nil
local function buildAbstractBg()
    abstractBg = gfx.image.new(400, 240, gfx.kColorBlack)
    gfx.pushContext(abstractBg)
        gfxp.set('wave-1i')
        gfx.fillRect(0, 0, 400, 240)
    gfx.popContext()
end

local function drawScanlineBg()
    if not abstractBg then buildAbstractBg() end
    abstractBg:draw(0, 0)
    gfx.setColor(gfx.kColorBlack)
end

local function fillCircleWithBg(r)
    local ri = math.ceil(r)
    gfxp.set('wave-1i')
    for dy = -ri, ri do
        local y = S.cy + dy
        if y >= 0 and y <= 239 then
            local sq = r*r - dy*dy
            if sq >= 0 then
                local chordX = math.floor(math.sqrt(sq))
                gfx.drawLine(S.cx - chordX, y, S.cx + chordX, y)
            end
        end
    end
    gfxp.set('white')
end

local function drawArc(innerR, outerR, arcStart, arcSweep, invert)
    if arcSweep >= 359 then
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(S.cx, S.cy, sc(outerR))
        fillCircleWithBg(sc(innerR))
        return
    end
    local steps = math.max(24, math.ceil(arcSweep / 3))
    local da = arcSweep / steps
    local oi = sc(innerR)
    local oo = sc(outerR)
    gfx.setColor(invert and gfx.kColorBlack or gfx.kColorWhite)
    for i = 0, steps-1 do
        local a1  = math.rad(arcStart + i*da)
        local a2  = math.rad(arcStart + (i+1)*da)
        local x1o = S.cx + oo*math.sin(a1); local y1o = S.cy - oo*math.cos(a1)
        local x2o = S.cx + oo*math.sin(a2); local y2o = S.cy - oo*math.cos(a2)
        local x1i = S.cx + oi*math.sin(a1); local y1i = S.cy - oi*math.cos(a1)
        local x2i = S.cx + oi*math.sin(a2); local y2i = S.cy - oi*math.cos(a2)
        gfx.fillPolygon(math.floor(x1o), math.floor(y1o),
                        math.floor(x2o), math.floor(y2o),
                        math.floor(x2i), math.floor(y2i),
                        math.floor(x1i), math.floor(y1i))
    end
end

local function drawBridgeShape(angle_deg, midR, halfLen, halfW)
    local angle = math.rad(angle_deg)
    local r  = sc(midR)
    local bx = S.cx + r * math.sin(angle)
    local by = S.cy - r * math.cos(angle)
    local hh = halfLen * S.zoom
    local hw = halfW   * S.zoom
    local ca = math.cos(angle)
    local sa = math.sin(angle)
    local function rot(px, py)
        return bx + px*ca - py*sa, by + px*sa + py*ca
    end
    local x1,y1 = rot(-hw,-hh)
    local x2,y2 = rot( hw,-hh)
    local x3,y3 = rot( hw, hh)
    local x4,y4 = rot(-hw, hh)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillPolygon(x1,y1, x2,y2, x3,y3, x4,y4)
end

-- Gegner-Sprites: lazily erstellt beim ersten Aufruf (vermeidet Absturz beim Laden)
-- Gegner-Sprites: lazily erstellt beim ersten Aufruf (vermeidet Absturz beim Laden)
local enemyImageGhost  = nil   -- Geist (Standard)
local enemyImageHunter = nil   -- Jäger (folgt Spieler)
local enemyImageInvisible = nil -- Unsichtbarer (periodisch unsichtbar)
local enemyImageGuardian = nil -- Wächter (blockiert Brücken)
local enemyImageDead   = nil

local function initSprites()
    if enemyImageGhost then return end

    -- Hilfsfunktion: Basis-Körper + Tropfen zeichnen
    local function drawBody(white)
        if white then gfx.setColor(gfx.kColorWhite) else gfx.setColor(gfx.kColorBlack) end
        gfx.fillRect(6, 4, 20, 20)   -- Koerper
        gfx.fillRect(8,  24, 2, 3)   -- Tropfen links
        gfx.fillRect(13, 24, 3, 5)   -- Tropfen mitte-links
        gfx.fillRect(18, 24, 2, 2)   -- Tropfen mitte-rechts
        gfx.fillRect(22, 24, 2, 4)   -- Tropfen rechts
    end
    local function drawOutline()
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(5, 3, 22, 22)   -- Koerper-Umriss
        gfx.fillRect(7, 24, 4, 5)    -- Tropfen links Umriss
        gfx.fillRect(12, 24, 5, 7)   -- Tropfen mitte-links Umriss
        gfx.fillRect(17, 24, 4, 4)   -- Tropfen mitte-rechts Umriss
        gfx.fillRect(21, 24, 4, 6)   -- Tropfen rechts Umriss
    end
    local function drawEyes(x1, y1, x2, y2, w, h)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(x1, y1, w, h)
        gfx.fillRect(x2, y2, w, h)
    end

    -- === GEIST (Standard) ===
    enemyImageGhost = gfx.image.new(32, 32, gfx.kColorClear)
    if enemyImageGhost then
        gfx.pushContext(enemyImageGhost)
            drawOutline()
            drawBody(true)
            drawEyes(10, 12, 19, 12, 3, 3)  -- normale runde Augen
        gfx.popContext()
    end

    -- === JÄGER (riesige wütende Schlitzaugen) ===
    enemyImageHunter = gfx.image.new(32, 32, gfx.kColorClear)
    if enemyImageHunter then
        gfx.pushContext(enemyImageHunter)
            drawOutline()
            drawBody(true)
            -- Wütende Schlitzaugen (dicke diagonale Balken)
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(8,  11, 6, 3)   -- linkes Auge breit
            gfx.fillRect(18, 11, 6, 3)   -- rechtes Auge breit
            -- Pupillen klein weiss
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(11, 12, 2, 1)
            gfx.fillRect(21, 12, 2, 1)
        gfx.popContext()
    end

    -- === UNSICHTBARER (Körper nur gestreift/gerastert statt solid) ===
    enemyImageInvisible = gfx.image.new(32, 32, gfx.kColorClear)
    if enemyImageInvisible then
        gfx.pushContext(enemyImageInvisible)
            drawOutline()
            -- Körper: horizontale Streifen (weiss-schwarz-weiss-schwarz)
            gfx.setColor(gfx.kColorBlack)
            for y = 6, 22, 4 do
                gfx.fillRect(6, y, 20, 2)
            end
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(8,  24, 2, 3)
            gfx.fillRect(13, 24, 3, 5)
            gfx.fillRect(18, 24, 2, 2)
            gfx.fillRect(22, 24, 2, 4)
            -- Leere Augen (weisse Löcher)
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(10, 12, 3, 3)
            gfx.fillRect(19, 12, 3, 3)
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(11, 13, 1, 1)
            gfx.fillRect(20, 13, 1, 1)
        gfx.popContext()
    end

    -- === WÄCHTER (dicker schwarzer Schild + kleine Augen oben) ===
    enemyImageGuardian = gfx.image.new(32, 32, gfx.kColorClear)
    if enemyImageGuardian then
        gfx.pushContext(enemyImageGuardian)
            drawOutline()
            -- Oberer Koerper weiss
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(6, 4, 20, 8)    -- obere Hälfte
            -- Schildbalken (massive schwarze Mitte)
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(5, 12, 22, 8)   -- dicker Querbalken
            -- Unterer Koerper weiss
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(6, 20, 20, 4)   -- unterer Rest
            gfx.fillRect(8,  24, 2, 3)
            gfx.fillRect(13, 24, 3, 5)
            gfx.fillRect(18, 24, 2, 2)
            gfx.fillRect(22, 24, 2, 4)
            -- Augen klein oben
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(11, 6, 3, 3)
            gfx.fillRect(18, 6, 3, 3)
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(12, 7, 1, 1)
            gfx.fillRect(19, 7, 1, 1)
        gfx.popContext()
    end

    -- Toter Geist (unverändert)
    enemyImageDead = gfx.image.new(32, 32, gfx.kColorClear)
    if enemyImageDead then
        gfx.pushContext(enemyImageDead)
            gfx.setColor(gfx.kColorWhite)
            -- Koerper-Rahmen (2px breit damit bei 0.5x scale 1px sichtbar)
            gfx.fillRect(6,  4,  20, 2)   -- oben
            gfx.fillRect(6,  22, 20, 2)   -- unten
            gfx.fillRect(6,  4,  2,  20)  -- links
            gfx.fillRect(24, 4,  2,  20)  -- rechts
            -- Tropfen (weiss gefuellt)
            gfx.fillRect(8,  24, 2, 3)
            gfx.fillRect(13, 24, 3, 5)
            gfx.fillRect(18, 24, 2, 2)
            gfx.fillRect(22, 24, 2, 4)
            -- X-Augen: 5 weisse 2x2-Bloecke an geraden Koords
            gfx.fillRect(8,  10, 2, 2)   -- oben-links L
            gfx.fillRect(12, 10, 2, 2)   -- oben-rechts L
            gfx.fillRect(10, 12, 2, 2)   -- mitte L
            gfx.fillRect(8,  14, 2, 2)   -- unten-links L
            gfx.fillRect(12, 14, 2, 2)   -- unten-rechts L
            gfx.fillRect(18, 10, 2, 2)   -- oben-links R
            gfx.fillRect(22, 10, 2, 2)   -- oben-rechts R
            gfx.fillRect(20, 12, 2, 2)   -- mitte R
            gfx.fillRect(18, 14, 2, 2)   -- unten-links R
            gfx.fillRect(22, 14, 2, 2)   -- unten-rechts R
        gfx.popContext()
    end
end

-- Zeichnet den Gegner rotiert; typ = 'ghost','hunter','invisible','guardian'
local function drawEnemyAtAngle(px, py, hl, hw, angleDeg, etype)
    initSprites()
    local img
    if etype == 'hunter' then
        img = enemyImageHunter
    elseif etype == 'invisible' then
        img = enemyImageInvisible
    elseif etype == 'guardian' then
        img = enemyImageGuardian
    else
        img = enemyImageGhost
    end
    if not img then return end
    local scale = math.max(hw / 14.0, 0.25)
    gfx.setImageDrawMode(gfx.kDrawModeInverted)
    img:drawRotated(math.floor(px), math.floor(py), angleDeg, scale)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

-- ---------------------------------------------------------------------------
function drawBoard()
    drawScanlineBg()
    local nowMs = playdate.getCurrentTimeMilliseconds()

    -- 1) Draw all ring segments (Tiefe: innere Ringe schmaler)
    for slot = 1, S.RING_COUNT do
        local ring = S.RINGS[slot]
        local depth = 1.0 - (slot - 1) / math.max(1, S.RING_COUNT - 1) * 0.55
        local mid   = (ring.inner + ring.outer) * 0.5
        local half  = (ring.outer - ring.inner) * 0.5 * depth
        local dInner = mid - half
        local dOuter = mid + half
        for _, seg in ipairs(ring.segs) do
            if seg.arcW >= 360 then
                drawArc(dInner, dOuter, 0, 360)
            else
                local as = segArcStart(slot, seg)
                drawArc(dInner, dOuter, as, seg.arcW, false)
            end
        end
    end

    -- 2) Draw bridges on each gap
    for gap = 1, S.RING_COUNT do
        local bGM, bHL, bHW
        if gap < S.RING_COUNT then
            local ri = S.RINGS[gap]
            local ro = S.RINGS[gap + 1]
            bGM = (ri.inner + ro.outer) * 0.5
            bHL = (ri.inner - ro.outer) * 0.5 + 4
            local rawHW = math.min((ri.outer - ri.inner) * 0.5, (ro.outer - ro.inner) * 0.5)
            -- Schmaler je weiter innen (gap=1 = außen, gap=RING_COUNT = innen)
            local innerFactor = 1.0 - (gap - 1) / math.max(1, S.RING_COUNT - 1) * 0.6
            bHW = rawHW * innerFactor
            -- Segment 6 (3 Arcs) hat schmalere Brücken
            local ring_gap = S.RINGS[gap]
            if #ring_gap.segs == 3 then bHW = bHW * 0.65 end
            local ring_gapp1 = S.RINGS[gap + 1]
            if ring_gapp1 and #ring_gapp1.segs == 3 then bHW = bHW * 0.65 end
        else
            local ri = S.RINGS[S.RING_COUNT]
            bGM = (ri.inner + S.CENTER_R) * 0.5
            bHL = (ri.inner - S.CENTER_R) * 0.5 + 4
            bHW = 2
        end

        local ring = S.RINGS[gap]
        for si, seg in ipairs(ring.segs) do
            local bas = segBridgeAnglesFrom(gap, seg, seg.bOff)
            for bi, ba in ipairs(bas) do
                local bs = S.bStates[gap] and S.bStates[gap][si] and S.bStates[gap][si][bi]
                if bs then
                    -- Closeable: animate open/close
                    if bs.state ~= 'closed' then
                        local MIN_T   = (4 + 5) / (2 * bHL)
                        local effT    = math.max(bs.t, MIN_T)
                        local flicker = (bs.state == 'open' and bs.timer <= S.BRIDGE_WARN)
                            and (math.floor(nowMs / 80) % 3 == 0)
                        if not flicker then
                            local visLen   = bHL * effT
                            local midShift = bHL * (1 - effT)
                            drawBridgeShape(ba, bGM + midShift, visLen, bHW)
                        end
                    end
                else
                    -- Static: always visible
                    drawBridgeShape(ba, bGM, bHL, bHW)
                end
            end
        end

        -- Draw up-bridges (attached to inner ring, span gap outward)
        if gap < S.RING_COUNT then
            local innerRing = S.RINGS[gap + 1]
            for si, seg in ipairs(innerRing.segs) do
                if seg.bOff_up and #seg.bOff_up > 0 then
                    local bas = segBridgeAnglesFrom(gap + 1, seg, seg.bOff_up)
                    for bi, ba in ipairs(bas) do
                        local bs = S.bStates_up[gap+1] and S.bStates_up[gap+1][si] and S.bStates_up[gap+1][si][bi]
                        if bs then
                            if bs.state ~= 'closed' then
                                local MIN_T   = (4 + 5) / (2 * bHL)
                                local effT    = math.max(bs.t, MIN_T)
                                local flicker = (bs.state == 'open' and bs.timer <= S.BRIDGE_WARN)
                                    and (math.floor(nowMs / 80) % 3 == 0)
                                if not flicker then
                                    local visLen   = bHL * effT
                                    local midShift = bHL * (1 - effT)
                                    drawBridgeShape(ba, bGM + midShift, visLen, bHW)
                                end
                            end
                        else
                            drawBridgeShape(ba, bGM, bHL, bHW)
                        end
                    end
                end
            end
        end
    end

    -- Pulsierender Mittelpunkt (dezent)
    local pulse = 1.0 + 0.06 * math.sin(playdate.getCurrentTimeMilliseconds() / 1000 * math.pi * 2 * 1.2)
    local pulseR = math.max(2, sc(S.CENTER_R) * pulse)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(S.cx, S.cy, pulseR)
end

-- ---------------------------------------------------------------------------
function drawTrailParticles()
    local n = #S.playerHistory
    for i, h in ipairs(S.playerHistory) do
        local t  = i / n
        local sz = math.max(1, math.floor(t * 6 + 0.5))
        local hf = math.floor(sz / 2)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(math.floor(h.x) - hf, math.floor(h.y) - hf, sz, sz)
    end
    for _, p in ipairs(S.particles) do
        local t  = p.life / S.TRAIL_LIFE
        local sz = (t > 0.66) and 3 or (t > 0.33) and 2 or 1
        local hf = math.floor(sz / 2)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(math.floor(p.x) - hf, math.floor(p.y) - hf, sz, sz)
    end
end

-- ---------------------------------------------------------------------------
function drawPlayer()
    -- Flimmern waehrend Unverwundbarkeit nach Treffer
    if (S.playerHitTimer or 0) > 0 and math.floor((S.playerHitTimer or 0) * 8) % 2 == 0 then
        return
    end
    local px, py
    if S.transiting then
        local toRing = math.max(1, math.min(S.RING_COUNT, S.playerRing + S.transDir))
        local r1 = sc(S.RINGS[S.playerRing].mid)
        local r2 = sc(S.RINGS[toRing].mid)
        local r  = r1 + (r2 - r1) * S.transT
        local a  = math.rad(S.transAngle)
        px = S.cx + r * math.sin(a)
        py = S.cy - r * math.cos(a)
    else
        px, py = entityPos(S.playerRing, S.playerAngle)
    end
    local ipx = math.floor(px)
    local ipy = math.floor(py)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(ipx, ipy, 5)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(ipx, ipy, 2)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(ipx + 1, ipy - 2, 1, 1)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawLine(ipx - 3, ipy - 4, ipx - 4, ipy - 5)
    gfx.drawLine(ipx,     ipy - 5, ipx,     ipy - 6)
    gfx.drawLine(ipx + 3, ipy - 4, ipx + 4, ipy - 5)
end

-- ---------------------------------------------------------------------------
function drawEnemies()
    -- Funken-Trail: diagonale schwarze Striche in verschiedene Richtungen
    local n = #S.enemyParticles
    local dirs = {{1,1},{-1,1},{1,-1},{-1,-1},{1,0},{0,1}}
    for i, p in ipairs(S.enemyParticles) do
        local t   = i / math.max(1, n)
        local ix  = math.floor(p.x)
        local iy  = math.floor(p.y)
        local dir = dirs[((i - 1) % #dirs) + 1]
        local ox  = ((i * 7) % 5) - 2
        local oy  = ((i * 13) % 5) - 2
        gfx.setColor(gfx.kColorBlack)
        if t > 0.65 then
            gfx.drawLine(ix + ox, iy + oy, ix + ox + dir[1]*3, iy + oy + dir[2]*3)
            local dir2 = dirs[((i + 2) % #dirs) + 1]
            gfx.drawLine(ix + ox, iy + oy, ix + ox + dir2[1]*2, iy + oy + dir2[2]*2)
        elseif t > 0.35 then
            gfx.drawLine(ix + ox, iy + oy, ix + ox + dir[1]*2, iy + oy + dir[2]*2)
        else
            gfx.fillRect(ix + ox, iy + oy, 1, 1)
        end
    end
    -- Burst-Partikel bei Gegner-Kollision
    for _, p in ipairs(S.burstParticles) do
        local t  = p.life / p.maxLife
        local sz = (t > 0.66) and 3 or (t > 0.33) and 2 or 1
        local hf = math.floor(sz / 2)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(math.floor(p.x) - hf, math.floor(p.y) - hf, sz, sz)
    end
    for _, e in ipairs(S.enemies) do
        -- Unsichtbarer Gegner: nicht zeichnen wenn unsichtbar
        if e.type == 'invisible' and e.invisVisible == false then goto continueEnemy end
        local px, py, hl, hw, ang
        if e.spawning then
            -- Gleitet von r=0 (Mittelpunkt) entlang der Brücke bis zum innersten Ring
            local ring = S.RINGS[S.RING_COUNT]
            local a = math.rad(e.angle)
            local r = sc(ring.mid) * e.spawnT
            px = S.cx + r * math.sin(a)
            py = S.cy - r * math.cos(a)
            local depth = 1.0 - (S.RING_COUNT - 1) / math.max(1, S.RING_COUNT - 1) * 0.55
            local half = (ring.outer - ring.inner) * depth * S.zoom * 0.5
            hl = half; hw = half; ang = e.angle
        elseif e.onGap then
            local gap = e.gapDir
            local ri  = S.RINGS[gap]
            local ro  = S.RINGS[gap + 1]
            if not (ri and ro) then goto continueEnemy end
            px, py = entityPosOnGap(gap, e.gapT, e.gapAngle)
            do
                local rawHW = math.min((ri.outer - ri.inner) * 0.5, (ro.outer - ro.inner) * 0.5)
                local innerFactor = 1.0 - (gap - 1) / math.max(1, S.RING_COUNT - 1) * 0.6
                hw = rawHW * innerFactor * S.zoom
                if #ri.segs == 3 then hw = hw * 0.65 end
                if #ro.segs == 3 then hw = hw * 0.65 end
                hl = hw
            end
            ang = e.gapAngle
        else
            px, py = entityPos(e.ring, e.angle)
            local ring = S.RINGS[e.ring or 1]
            -- Tiefe beruecksichtigen: gleicher Faktor wie beim Zeichnen der Ringe
            local depth = 1.0 - ((e.ring or 1) - 1) / math.max(1, S.RING_COUNT - 1) * 0.55
            local half = (ring.outer - ring.inner) * depth * S.zoom * 0.5
            hl = half; hw = half; ang = e.angle
        end
        drawEnemyAtAngle(px, py, hl, hw, ang, e.type)
        ::continueEnemy::
    end
end

-- ---------------------------------------------------------------------------
function drawImplode(t)
    -- Schwarzes Loch: wachsender schwarzer Kreis frisst die Ringe von innen nach aussen.
    -- Board bleibt bei eingefrorernem Zoom stehen - nur der schwarze Kern waechst.
    local pullTE = t * t * (3 - 2 * t)  -- smoothstep ueber gesamte Dauer

    -- Screenshake: staerker in der Mitte der Animation
    local shakeAmp = math.sin(t * math.pi) * 14
    local shakeX   = math.floor((math.random() * 2 - 1) * shakeAmp)
    local shakeY   = math.floor((math.random() * 2 - 1) * shakeAmp)

    -- Board unveraendert zeichnen (Zoom eingefroren)
    local savZoom = S.zoom
    S.zoom = S.implodeBaseZoom or S.zoom
    local savCx, savCy = S.cx, S.cy
    S.cx = 200 + shakeX
    S.cy = 120 + shakeY
    drawBoard()
    S.cx, S.cy = savCx, savCy
    S.zoom = savZoom

    -- Spieler-Punkt gleitet in den Kern
    if t < 0.7 then
        local dotT  = t / 0.7
        local dotTE = dotT * dotT * (3 - 2 * dotT)
        local px = S.ppx + (200 + shakeX - S.ppx) * dotTE
        local py = S.ppy + (120 + shakeY - S.ppy) * dotTE
        local pr = math.max(1, math.floor(5 * (1 - dotTE) + 0.5))
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(math.floor(px), math.floor(py), pr)
    end

    -- Schwarzes Loch waechst vom Zentrum nach aussen und verschluckt alles
    local holeR = math.floor(pullTE * pullTE * 230)
    if holeR > 0 then
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(200 + shakeX, 120 + shakeY, holeR)
    end
end

-- ---------------------------------------------------------------------------
function drawHUD()
end

-- ---------------------------------------------------------------------------
function drawGameOver()
    drawScanlineBg()
    -- Titel "GAME OVER" fett, 2.5x skaliert, zentriert
    local tw, th = gfx.getTextSize("GAME OVER")
    local titleImg = gfx.image.new(tw + 4, th + 2)
    gfx.pushContext(titleImg)
    gfx.drawText("GAME OVER", 1, 1)
    gfx.drawText("GAME OVER", 2, 1)
    gfx.popContext()
    local tScale = 2.5
    local tImgW = (tw + 4) * tScale
    titleImg:drawScaled(math.floor((400 - tImgW) / 2), 80, tScale)
    -- Unterer Balken
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 196, 400, 44)
    -- A-Taste: weisser Kreis, A fett + exakt zentriert, RESTART daneben (weiss)
    local aX, aY = 130, 218
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(aX, aY, 9)
    local aw, ah = gfx.getTextSize("A")
    local aTextX = aX - math.floor((aw + 1) / 2)
    local aTextY = aY - math.floor(ah / 2)
    gfx.drawText("A", aTextX, aTextY)
    gfx.drawText("A", aTextX + 1, aTextY)
    gfx.setImageDrawMode(gfx.kDrawModeInverted)
    gfx.drawText("RESTART", aX + 13, aTextY)
    gfx.drawText("RESTART", aX + 14, aTextY)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    -- B-Taste: weisser Kreis, B fett + exakt zentriert, EXIT daneben (weiss)
    local bX, bY = 258, 218
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(bX, bY, 9)
    local bw, bh = gfx.getTextSize("B")
    local bTextX = bX - math.floor((bw + 1) / 2)
    local bTextY = bY - math.floor(bh / 2)
    gfx.drawText("B", bTextX, bTextY)
    gfx.drawText("B", bTextX + 1, bTextY)
    gfx.setImageDrawMode(gfx.kDrawModeInverted)
    gfx.drawText("EXIT", bX + 13, bTextY)
    gfx.drawText("EXIT", bX + 14, bTextY)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

-- ---------------------------------------------------------------------------
function drawWin()
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, 400, 240)
    gfx.setImageDrawMode(gfx.kDrawModeInverted)
    gfx.drawText('YOU  WIN!', 160, 100)
    gfx.drawText('All ' .. S.MAX_LEVEL .. ' levels cleared!', 128, 130)
    gfx.drawText('PRESS  A  TO  RETRY', 108, 170)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

-- ---------------------------------------------------------------------------
-- Konstanten fuer Titelkreis
local TITLE_CX    = 200
local TITLE_CY    = 120
local TITLE_R     = 90
local TITLE_THICK = 16

-- Zeichnet nur Hintergrund + Menuetext (fuer alle Titelphasen wiederverwendbar)
local function drawTitleBase()
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, 400, 240)

    local items   = {"START GAME", "OPTIONS", "EXIT"}
    local itemH   = 22
    local totalH  = #items * itemH
    local startY  = TITLE_CY - math.floor(totalH / 2) + 2
    gfx.setColor(gfx.kColorWhite)
    for i, item in ipairs(items) do
        local iw, ih = gfx.getTextSize(item)
        local ix = math.floor((400 - iw) / 2)
        local iy = startY + (i - 1) * itemH + math.floor((itemH - ih) / 2)
        gfx.setImageDrawMode(gfx.kDrawModeInverted)
        gfx.drawText(item, ix,   iy); gfx.drawText(item, ix+1, iy)
        gfx.drawText(item, ix,   iy+1); gfx.drawText(item, ix+1, iy+1)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        -- Auswahlpfeil links
        if i == S.titleMenuIdx then
            local arrowX = ix - 10
            local arrowMY = iy + math.floor(ih / 2)
            gfx.setColor(gfx.kColorWhite)
            gfx.fillPolygon(arrowX+6, arrowMY, arrowX, arrowMY-4, arrowX, arrowMY+4)
        end
    end
    -- Kurbel-Levelauswahl: nur sichtbar wenn Level > 1 ausgewaehlt
    if S.titleMenuIdx == 1 and (S.selectedLevel or 1) > 1 then
        local lstr = "< Lv " .. S.selectedLevel .. " >"
        local lw, _ = gfx.getTextSize(lstr)
        gfx.setImageDrawMode(gfx.kDrawModeInverted)
        gfx.drawText(lstr, math.floor((400 - lw) / 2), startY + #items * itemH + 4)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end
end

function drawTitleScreen()
    drawTitleBase()

    -- Kreis fadet ein (Bogen von 0 bis 360 * titleCircleT)
    if S.titleCircleT > 0 then
        local sweep = math.min(1.0, S.titleCircleT) * 360
        local steps = math.max(3, math.ceil(sweep / 3))
        local da    = sweep / steps
        local r1    = TITLE_R - TITLE_THICK
        local r2    = TITLE_R
        gfx.setColor(gfx.kColorWhite)
        for i = 0, steps - 1 do
            local a1 = math.rad(-90 + i * da)
            local a2 = math.rad(-90 + (i + 1) * da)
            gfx.fillPolygon(
                math.floor(TITLE_CX + r2*math.cos(a1)), math.floor(TITLE_CY + r2*math.sin(a1)),
                math.floor(TITLE_CX + r2*math.cos(a2)), math.floor(TITLE_CY + r2*math.sin(a2)),
                math.floor(TITLE_CX + r1*math.cos(a2)), math.floor(TITLE_CY + r1*math.sin(a2)),
                math.floor(TITLE_CX + r1*math.cos(a1)), math.floor(TITLE_CY + r1*math.sin(a1))
            )
        end
    end
end

-- Kreis fuellt sich schwarz (Ring schliesst innen)
function drawTitleFill(t)
    local tE = t * t * (3 - 2 * t)
    drawTitleBase()
    -- Aeussere Scheibe weiss
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(TITLE_CX, TITLE_CY, TITLE_R)
    -- Inneres schwarz mit schrumpfendem Radius
    local innerR = math.floor((TITLE_R - TITLE_THICK) * (1 - tE))
    if innerR > 0 then
        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(TITLE_CX, TITLE_CY, innerR)
    end
end

-- Zoom out: schwarzer Kreis wird zum innersten Ring des Spielfelds
function drawTitleZoomOut(t)
    local tE       = t * t * (3 - 2 * t)
    local startZoom = TITLE_R / S.CENTER_R  -- Zoom bei dem CENTER_R-Kreis = TITLE_R auf Screen
    local endZoom   = S.ZOOM_TABLE[1]
    local savCx, savCy, savZoom = S.cx, S.cy, S.zoom
    S.cx   = 200; S.cy = 120
    S.zoom = startZoom + (endZoom - startZoom) * tE
    drawBoard()
    S.cx, S.cy, S.zoom = savCx, savCy, savZoom
end


