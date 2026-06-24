-- controller.lua: update and setup functions (segment-based architecture)

local math <const> = math

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

-- Prüft ob ein Wächter eine Brücke blockiert (nah am Spieler)
local function guardianBlocksBridge(angleDeg)
    for _, e in ipairs(S.enemies) do
        if e.type == 'guardian' and not e.spawning and math.abs(e.ring - S.playerRing) <= 1 then
            if angleDist(e.angle, angleDeg) < 15 then
                return true
            end
        end
    end
    return false
end

local function makeBridgeStates(seg, slot)
    local states = {}
    -- Welle von außen nach innen: äußerster Gap startet frisch offen,
    -- innere Gaps sind weiter im Zyklus (schließen früher).
    local phase = (slot - 1) / 4.0   -- 0.0 (außen) … 1.0 (innen)
    local t = S.BRIDGE_OPEN_DUR * (1.0 - phase)
    for i, cl in ipairs(seg.closeable) do
        if cl then
            states[i] = { state='open', timer=t, t=1.0 }
        else
            states[i] = nil
        end
    end
    return states
end

local function makeBridgeStatesUp(seg, slot)
    local states = {}
    local phase = (slot - 1) / 4.0
    local t = S.BRIDGE_OPEN_DUR * (1.0 - phase)
    for i, cl in ipairs(seg.closeable_up or {}) do
        if cl then
            states[i] = { state='open', timer=t, t=1.0 }
        end
    end
    return states
end

local function copySegDef(def)
    local bOff = {}; for _, v in ipairs(def.bOff)              do table.insert(bOff,  v) end
    local cl   = {}; for _, v in ipairs(def.closeable)         do table.insert(cl,    v) end
    local bUp  = {}; for _, v in ipairs(def.bOff_up or {})     do table.insert(bUp,   v) end
    local clUp = {}; for _, v in ipairs(def.closeable_up or {}) do table.insert(clUp, v) end
    return { arcW=def.arcW, startOff=def.startOff, bOff=bOff, closeable=cl, bOff_up=bUp, closeable_up=clUp }
end

local function buildSlot(slot, def)
    local segs = {}
    for _, sd in ipairs(def.segs) do table.insert(segs, copySegDef(sd)) end
    S.RINGS[slot] = {
        mid   = S.SLOT_MID[slot],
        inner = S.SLOT_INNER[slot],
        outer = S.SLOT_OUTER[slot],
        rot   = def.rot,
        segs  = segs,
    }
end

local function initBStates(slot)
    S.bStates[slot]    = {}
    S.bStates_up[slot] = {}
    for si, seg in ipairs(S.RINGS[slot].segs) do
        S.bStates[slot][si]    = makeBridgeStates(seg, slot)
        S.bStates_up[slot][si] = makeBridgeStatesUp(seg, slot)
    end
end

-- ---------------------------------------------------------------------------
function rebuildRingsFromQueue()
    S.RINGS = {}
    for slot = 1, S.RING_COUNT do
        local qi = ((S.queueHead + slot - 2) % S.TOTAL_RINGS) + 1
        buildSlot(slot, S.RING_QUEUE_ALL[qi])
    end
end

-- ---------------------------------------------------------------------------
function advanceQueue()
    S.queueHead     = (S.queueHead % S.TOTAL_RINGS) + 1
    S.queueAdvances = S.queueAdvances + 1
    -- Wenn alle Queue-Einträge im Fenster angekommen sind → finalStage
    if S.queueAdvances >= S.TOTAL_RINGS - S.RING_COUNT then
        S.finalStage = true
    end

    for slot = 1, S.RING_COUNT - 1 do
        S.RINGS[slot].rot       = S.RINGS[slot + 1].rot
        S.RINGS[slot].segs      = S.RINGS[slot + 1].segs
        S.RINGS[slot]._rotState = S.RINGS[slot + 1]._rotState
        S.angles[slot]          = S.angles[slot + 1]
        S.ringDeltas[slot]      = 0
        S.bStates[slot]         = S.bStates[slot + 1]
        S.bStates_up[slot]      = S.bStates_up[slot + 1]
    end
    S.ringDeltas[S.RING_COUNT] = 0

    local qi  = ((S.queueHead + S.RING_COUNT - 2) % S.TOTAL_RINGS) + 1
    buildSlot(S.RING_COUNT, S.RING_QUEUE_ALL[qi])
    local newRot = S.RING_QUEUE_ALL[qi].rot
    S.angles[S.RING_COUNT]      = (newRot and newRot.startAngle) or 0
    S.RINGS[S.RING_COUNT]._rotState = nil
    initBStates(S.RING_COUNT)
end

-- ---------------------------------------------------------------------------
-- retreatQueue: macht einen advanceQueue-Schritt rueckgaengig.
-- Die Slots verschieben sich nach innen (Slot[i] = Slot[i-1]), der aeusserste
-- Ring (Slot 1) wird aus der alten Queue-Position wiederhergestellt.
-- Gibt true zurueck wenn erfolgreich, false wenn kein Vorschub mehr vorhanden.
local function retreatQueue()
    if (S.queueAdvances or 0) <= 0 then return false end
    -- queueHead einen Schritt zuruecksetzen
    S.queueHead     = ((S.queueHead - 2) % S.TOTAL_RINGS) + 1
    S.queueAdvances = S.queueAdvances - 1
    if S.finalStage and S.queueAdvances < S.TOTAL_RINGS - S.RING_COUNT then
        S.finalStage = false
    end
    -- Alle Slots einen nach innen schieben: Slot[i] = Slot[i-1]
    for slot = S.RING_COUNT, 2, -1 do
        S.RINGS[slot].rot       = S.RINGS[slot-1].rot
        S.RINGS[slot].segs      = S.RINGS[slot-1].segs
        S.RINGS[slot]._rotState = S.RINGS[slot-1]._rotState
        S.angles[slot]          = S.angles[slot-1]
        S.ringDeltas[slot]      = 0
        S.bStates[slot]         = S.bStates[slot-1]
        S.bStates_up[slot]      = S.bStates_up[slot-1]
    end
    -- Slot 1: aeusseren Ring aus alter Queue-Position wiederherstellen
    local qi = ((S.queueHead - 1) % S.TOTAL_RINGS) + 1
    buildSlot(1, S.RING_QUEUE_ALL[qi])
    local newRot = S.RING_QUEUE_ALL[qi].rot
    S.angles[1]          = (newRot and newRot.startAngle) or 0
    S.RINGS[1]._rotState = nil
    initBStates(1)
    -- Gegner: alle einen Slot nach innen verschieben (Slots haben sich nach innen geschoben)
    for i = #S.enemies, 1, -1 do
        local e = S.enemies[i]
        e.ring = e.ring + 1
        if e.onGap then e.gapDir = e.gapDir + 1 end
        if e.ring > S.RING_COUNT then
            table.remove(S.enemies, i)
        end
    end
    return true
end

-- ---------------------------------------------------------------------------
function updateBridges(dt)
    local lm = 1.0 + (S.level - 1) * 0.15

    -- Globale synchrone Pause: alle Ringe halten gleichzeitig kurz an
    S.globalPauseTimer = (S.globalPauseTimer or 0) + dt
    if S.globalPausing then
        if S.globalPauseTimer >= 0.8 then
            S.globalPausing     = false
            S.globalPauseTimer  = 0
        end
    else
        if S.globalPauseTimer >= 5.0 then
            S.globalPausing    = true
            S.globalPauseTimer = 0
        end
    end

    for slot = 1, S.RING_COUNT do
        local rot = S.RINGS[slot].rot
        local oldAngle = S.angles[slot]
        if rot and rot.speed > 0 and not S.globalPausing then
            local bm = S.RINGS[slot]._rotState
            if not bm then
                bm = { t=0, paused=false, pauseT=0, swingIdx=1, warnDir=false,
                       pauseEvery=math.max(2.0, 5.0 / lm) }
                S.RINGS[slot]._rotState = bm
            end
            if rot.swingPts then
                -- Swing-Ringe: Richtung kommt vom diff zum Zielpunkt
                local pts = rot.swingPts
                local tgt = pts[bm.swingIdx]
                if bm.paused then
                    bm.pauseT = bm.pauseT + dt
                    if bm.pauseT >= rot.pauseLen then
                        bm.paused = false; bm.pauseT = 0
                        bm.swingIdx = (bm.swingIdx % #pts) + 1
                    end
                else
                    local cur  = S.angles[slot]
                    local diff = ((tgt - cur + 180) % 360) - 180
                    -- Innere Ringe drehen schneller (Zahnrad-Effekt)
                    local speedMult = 1.0 + (slot - 1) * 0.12
                    local step = rot.speed * speedMult * lm * dt
                    bm.warnDir = math.abs(diff) < 22
                    if math.abs(diff) <= step + 0.5 then
                        S.angles[slot] = tgt % 360
                        bm.paused  = true; bm.pauseT = 0
                        bm.warnDir = false
                    else
                        S.angles[slot] = (cur + (diff > 0 and 1 or -1) * step) % 360
                    end
                end
            else
                -- Vollringe: Zahnrad — ungerade Slots CW, gerade Slots CCW
                local gearDir  = (slot % 2 == 1) and 1 or -1
                local speedMult = 1.0 + (slot - 1) * 0.12
                if bm.paused then
                    bm.pauseT = bm.pauseT + dt
                    if bm.pauseT >= rot.pauseLen then bm.paused=false; bm.pauseT=0 end
                else
                    S.angles[slot] = (S.angles[slot] + gearDir * rot.speed * speedMult * lm * dt) % 360
                    bm.t = bm.t + dt
                    if bm.t >= bm.pauseEvery then bm.paused=true; bm.t=0 end
                end
            end
        end
        S.ringDeltas[slot] = ((S.angles[slot] - oldAngle + 180) % 360) - 180
    end

    -- Tick bridge state machines
    for slot = 1, S.RING_COUNT do
        if S.bStates[slot] then
            for _, segStates in ipairs(S.bStates[slot]) do
                for _, bs in pairs(segStates) do
                    if bs then
                        if bs.state == 'open' then
                            bs.timer = bs.timer - dt
                            if bs.timer <= 0 then bs.state='closing'; bs.timer=S.BRIDGE_CLOSE_T end
                        elseif bs.state == 'closing' then
                            bs.timer = bs.timer - dt
                            bs.t     = math.max(0, bs.timer / S.BRIDGE_CLOSE_T)
                            if bs.timer <= 0 then bs.state='closed'; bs.t=0; bs.timer=S.BRIDGE_CLOSED_DUR end
                        elseif bs.state == 'closed' then
                            bs.timer = bs.timer - dt
                            if bs.timer <= 0 then bs.state='opening'; bs.timer=S.BRIDGE_OPEN_T end
                        elseif bs.state == 'opening' then
                            bs.timer = bs.timer - dt
                            bs.t     = math.max(0, 1.0 - bs.timer / S.BRIDGE_OPEN_T)
                            if bs.timer <= 0 then bs.state='open'; bs.t=1.0; bs.timer=S.BRIDGE_OPEN_DUR end
                        end
                    end
                end
            end
        end
    end

    -- Tick up-bridge state machines (inner-ring bridges facing outward)
    for slot = 1, S.RING_COUNT do
        if S.bStates_up[slot] then
            for _, segStates in ipairs(S.bStates_up[slot]) do
                for _, bs in pairs(segStates) do
                    if bs then
                        if bs.state == 'open' then
                            bs.timer = bs.timer - dt
                            if bs.timer <= 0 then bs.state='closing'; bs.timer=S.BRIDGE_CLOSE_T end
                        elseif bs.state == 'closing' then
                            bs.timer = bs.timer - dt
                            bs.t     = math.max(0, bs.timer / S.BRIDGE_CLOSE_T)
                            if bs.timer <= 0 then bs.state='closed'; bs.t=0; bs.timer=S.BRIDGE_CLOSED_DUR end
                        elseif bs.state == 'closed' then
                            bs.timer = bs.timer - dt
                            if bs.timer <= 0 then bs.state='opening'; bs.timer=S.BRIDGE_OPEN_T end
                        elseif bs.state == 'opening' then
                            bs.timer = bs.timer - dt
                            bs.t     = math.max(0, 1.0 - bs.timer / S.BRIDGE_OPEN_T)
                            if bs.timer <= 0 then bs.state='open'; bs.t=1.0; bs.timer=S.BRIDGE_OPEN_DUR end
                        end
                    end
                end
            end
        end
    end

    -- Carry player only if NOT on a full-circle ring
    local playerOnFull = (#S.RINGS[S.playerRing].segs == 1 and S.RINGS[S.playerRing].segs[1].arcW >= 360)
    if not S.transiting and not playerOnFull then
        S.playerAngle = (S.playerAngle + S.ringDeltas[S.playerRing]) % 360
    end
    for _, e in ipairs(S.enemies) do
        if not e.onGap then
            e.angle = (e.angle + S.ringDeltas[e.ring]) % 360
            if not e.spawning then
                -- e.seg immer aktuell halten damit clampToSeg das richtige Segment nutzt
                e.seg = findSeg(e.ring, e.angle)
                local seg = S.RINGS[e.ring].segs[e.seg]
                if seg then e.angle = clampToSeg(e.ring, seg, e.angle) end
            end
        end
    end
end

-- ---------------------------------------------------------------------------
function updatePlayer(dt)
    -- Treffer-Unverwundbarkeit runterzaehlen
    S.playerHitTimer = math.max(0, (S.playerHitTimer or 0) - dt)

    if S.scrolling then
        S.scrollT = S.scrollT + dt / S.SCROLL_DUR
        if S.scrollT >= 1.0 then
            S.scrollT   = 1.0
            S.scrolling = false
        else
            local t = S.scrollT
            local smooth = t * t * (3 - 2 * t)
            local target = S.scrollZoomStart * S.scrollZoomMult
            S.zoom = S.scrollZoomStart + (target - S.scrollZoomStart) * smooth
        end
        goto skipInput
    end

    if playdate.buttonJustPressed(playdate.kButtonA) then S.aBufTimer = S.BUF_TIME end
    if playdate.buttonJustPressed(playdate.kButtonB) then S.bBufTimer = S.BUF_TIME end

    if not S.transiting then
        S.playerAngle = (S.playerAngle + playdate.getCrankChange()) % 360
        local seg = S.RINGS[S.playerRing].segs[S.playerSeg]
        if seg then S.playerAngle = clampToSeg(S.playerRing, seg, S.playerAngle) end

        if S.aBufTimer > 0 then
            if S.conceptualRing >= S.TOTAL_RINGS then
                -- Am Kern: Brücke zum Mittelpunkt suchen
                local ok, ba = nearBridge(S.RING_COUNT, S.playerAngle)
                if ok then
                    S.transiting=true; S.transDir=1; S.transT=0; S.transAngle=ba
                    S.aBufTimer=0
                    sfxBridge()
                    onBridgeCross()
                else
                    -- Fallback: direkter Implode
                    S.gameState = S.STATE_IMPLODE
                    S.implodeT = 0.0
                    S.implodeBaseZoom = S.zoom
                    S.transiting = false
                    S.aBufTimer = 0
                    sfxCenter()
                    sfxImplode()
                    return
                end
            else
                local ok, ba = nearBridge(S.playerRing, S.playerAngle)
                if ok then
                    S.transiting=true; S.transDir=1; S.transT=0; S.transAngle=ba
                    S.aBufTimer=0
                    sfxBridge()
                    onBridgeCross()
                end
            end
        end
        S.aBufTimer = math.max(0, S.aBufTimer - dt)

        if S.bBufTimer > 0 then
            if S.conceptualRing > 1 then
                -- Rückwärts-Brücke auf Gap darunter suchen (wie A nur entgegengesetzt)
                local ok, ba = nearBridge(S.playerRing - 1, S.playerAngle, S.BRIDGE_HALF_BACK)
                if ok then
                    S.transiting=true; S.transDir=-1; S.transT=0; S.transAngle=ba
                    S.bBufTimer=0
                    sfxBridge()
                end
            else
                S.bBufTimer = 0
            end
        end
        S.bBufTimer = math.max(0, S.bBufTimer - dt)
    else
        S.transT = S.transT + dt / S.TRANS_TIME
        if S.transT >= 1.0 then
            if S.transDir == 1 then
                if S.conceptualRing >= S.TOTAL_RINGS then
                    -- Letzter Ring (Kern) → Level fertig!
                    S.gameState       = S.STATE_IMPLODE
                    S.implodeT        = 0.0
                    S.implodeBaseZoom = S.zoom
                    S.transiting = false
                    S.transT     = 1.0
                    sfxCenter()
                    sfxImplode()
                    return
                elseif S.conceptualRing == 1 then
                    -- Ring 1→2: Slot 1→2, keine Queue-Änderung
                    S.playerRing = 2
                    S.conceptualRing = 2
                elseif S.conceptualRing == 7 then
                    -- Ring 7→8: Slot 2→3 (innerster), keine Queue-Änderung
                    S.playerRing = 3
                    S.conceptualRing = 8
                else
                    -- Normalfall: Queue vorschieben, Mitte (Slot 2)
                    advanceQueue()
                    S.playerRing = 2
                    S.conceptualRing = S.conceptualRing + 1
                end
                S.scrolling      = false
            elseif S.transDir == -1 then
                if S.conceptualRing == 2 then
                    -- Ring 2→1: Slot 2→1, keine Queue-Änderung
                    S.playerRing = 1
                    S.conceptualRing = 1
                elseif S.conceptualRing == 8 then
                    -- Ring 8→7: Slot 3→2, keine Queue-Änderung
                    S.playerRing = 2
                    S.conceptualRing = 7
                else
                    -- Normal zurück: Queue zurück, Mitte
                    retreatQueue()
                    S.playerRing = 2
                    S.conceptualRing = S.conceptualRing - 1
                end
            end
            S.playerAngle = S.transAngle
            S.playerSeg   = findSeg(S.playerRing, S.playerAngle)
            S.transiting  = false
            S.transT      = 1.0
            S.ppx, S.ppy = entityPos(S.playerRing, S.playerAngle)
        end
    end

    ::skipInput::

    -- Zoom: während Transit smoothstep, danach direkt setzen
    local function zoomFor(r) return 1.0 + math.max(0, (r or 1) - 1) * S.ZOOM_PER_RING end
    if S.transiting then
        local toZoom = zoomFor(S.conceptualRing + S.transDir)
        local fromZoom = zoomFor(S.conceptualRing)
        local tE = S.transT * S.transT * (3 - 2 * S.transT)
        S.zoom = fromZoom + (toZoom - fromZoom) * tE
    else
        S.zoom = zoomFor(S.conceptualRing)
    end

    -- Position immer über entityPos (Zoom-Animation erzeugt Tunnel-Effekt)
    S.ppx, S.ppy = entityPos(S.playerRing, S.playerAngle)

    table.insert(S.particles, {x=S.ppx, y=S.ppy, life=S.TRAIL_LIFE})
    if #S.particles > 12 then table.remove(S.particles, 1) end
    for i = #S.particles, 1, -1 do
        S.particles[i].life = S.particles[i].life - dt
        if S.particles[i].life <= 0 then table.remove(S.particles, i) end
    end
    table.insert(S.playerHistory, {x=S.ppx, y=S.ppy})
    if #S.playerHistory > S.HISTORY_MAX then table.remove(S.playerHistory, 1) end
end

-- ---------------------------------------------------------------------------
function updateEnemies(dt)
    S.enemyRotation = (S.enemyRotation + 90 * dt) % 360
    -- Nach Respawn Gegner kurz einfrieren damit der Spieler sie sehen kann
    if S.enemyFreezeTimer > 0 then
        S.enemyFreezeTimer = S.enemyFreezeTimer - dt
        return
    end
    S.spawnTimer = S.spawnTimer - dt
    if S.spawnTimer <= 0 then
        S.spawnTimer = S.SPAWN_INTERVAL
        -- Offene Brücke vom Mittelpunkt zum innersten Ring suchen
        local allB = getBridgesOnGap(S.RING_COUNT)
        -- Auch Vorschau-Brücken des nächsten Queue-Eintrags berücksichtigen
        if S.conceptualRing and S.conceptualRing < S.TOTAL_RINGS then
            local qi_next = ((S.queueHead + S.RING_COUNT - 1) % S.TOTAL_RINGS) + 1
            local nextDef = S.RING_QUEUE_ALL[qi_next]
            if nextDef and nextDef.segs then
                for si, seg in ipairs(nextDef.segs) do
                    if seg.bOff_up and #seg.bOff_up > 0 then
                        local bas = segBridgeAnglesFrom(S.RING_COUNT, seg, seg.bOff_up)
                        for _, ba in ipairs(bas) do
                            table.insert(allB, { angle=ba, slot=S.RING_COUNT, seg=si, bridge=0, open=true, state=nil })
                        end
                    end
                end
            end
        end
        local openB = {}
        for _, b in ipairs(allB) do
            local fullyOpen = (not b.state) or (b.state.state == 'open')
            if fullyOpen then table.insert(openB, b) end
        end
        if #openB > 0 and #S.enemies < S.ENEMY_MAX then
            local b = openB[math.random(1, #openB)]
            local si = findSeg(S.RING_COUNT, b.angle)
            -- Gegnertyp Level-abhängig
            local r = math.random()
            local etype
            if S.level == 1 then
                etype = r < 0.7 and 'ghost' or 'hunter'
            elseif S.level == 2 then
                etype = r < 0.35 and 'ghost' or (r < 0.65 and 'hunter' or 'guardian')
            else
                etype = r < 0.2 and 'ghost' or (r < 0.5 and 'hunter' or 'guardian')
            end
            table.insert(S.enemies, {
                ring=S.RING_COUNT, seg=si, angle=b.angle % 360,
                onGap=false, gapDir=0, gapAngle=b.angle, gapT=0, gapIdx=0,
                spawning=true, spawnT=0.0,
                speed       = (S.ENEMY_SPEED_MIN + math.random() * (S.ENEMY_SPEED_MAX - S.ENEMY_SPEED_MIN)) * (etype == 'hunter' and 1.5 or 1),
                dir         = (math.random(2) == 1) and 1 or -1,
                wanderTimer = (S.WANDER_MIN or 0.8) + math.random() * ((S.WANDER_MAX or 3.0) - (S.WANDER_MIN or 0.8)),
                type = etype,
            })
        else
            S.spawnTimer = 0.5  -- keine Brücke offen, kurz warten
        end
    end

    for idx = #S.enemies, 1, -1 do
        local e = S.enemies[idx]
        if e.spawning then
            e.spawnT = e.spawnT + dt / 0.5
            if e.spawnT >= 1.0 then e.spawning = false; e.spawnT = 1.0 end
        elseif e.onGap then
            -- Brückenwinkel mit dem korrekten Ring mitführen (outer-bOff: gapIdx, up-bOff: gapIdx+1)
            e.gapAngle = (e.gapAngle + S.ringDeltas[e.gapDeltaSlot or e.gapIdx or e.ring]) % 360
            e.gapT = e.gapT - dt * S.ENEMY_GAP_SPD
            if e.gapT <= 0.0 then
                e.onGap = false
                e.ring  = e.gapDir
                e.angle = e.gapAngle
                e.seg   = findSeg(e.ring, e.angle)
                -- Winkel auf das gefundene Segment einrasten
                local arrSeg = S.RINGS[e.ring].segs[e.seg]
                if arrSeg then e.angle = clampToSeg(e.ring, arrSeg, e.angle) end
                e.gapT  = 0.0
            end
        else
            -- === TYP-SPEZIFISCH ===
            if e.type == 'hunter' then
                -- Jäger: jagt Spieler auf gleichem Ring, nutzt Brücken normal
                if e.ring == S.playerRing then
                    local diff = ((S.playerAngle - e.angle + 180) % 360) - 180
                    local step = e.speed * dt * 2
                    if math.abs(diff) > step then
                        e.angle = (e.angle + (diff > 0 and 1 or -1) * step) % 360
                    end
                    local seg = S.RINGS[e.ring] and S.RINGS[e.ring].segs[e.seg or 1]
                    if seg then e.angle = clampToSeg(e.ring, seg, e.angle) end
                    e.dir = (diff > 0) and 1 or -1
                    e.wanderTimer = 999
                end
                -- Auf anderem Ring: normales Bridge-Verhalten (kein eigener Code nötig)
            elseif e.type == 'guardian' then
                -- Wächter: blockiert Brücken nah am Spieler, verpufft nach 10s
                if not e.spawning and math.abs(e.ring - S.playerRing) <= 1 then
                    -- Timer starten wenn noch nicht aktiv
                    if not e.guardTimer then e.guardTimer = 10 end
                    e.guardTimer = e.guardTimer - dt
                    if e.guardTimer <= 0 then
                        -- Verpuffen
                        local gx, gy = entityPos(e.ring, e.angle)
                        for k = 1, 14 do
                            local ang = (k / 14) * math.pi * 2
                            local r   = 4 + math.random() * 10
                            table.insert(S.burstParticles, {
                                x=gx + math.cos(ang)*r, y=gy + math.sin(ang)*r,
                                life=S.TRAIL_LIFE * 4, maxLife=S.TRAIL_LIFE * 4
                            })
                        end
                        table.remove(S.enemies, idx)
                        goto continueEnemyLoop
                    end
                    -- Zur nächsten Brücke ziehen und blockieren
                    local gapToExit = e.ring - 1
                    local bridges = getBridgesOnGap(gapToExit)
                    local bestAng, bestDist = nil, 361
                    for _, b in ipairs(bridges) do
                        local d = angleDist(e.angle, b.angle)
                        if d < bestDist then bestDist = d; bestAng = b.angle end
                    end
                    if bestAng and bestDist > 5 then
                        local step = 60 * dt
                        local diff = ((bestAng - e.angle + 180) % 360) - 180
                        e.angle = (e.angle + (diff > 0 and 1 or -1) * step) % 360
                    end
                end
                -- kein skip — Wächter nutzt auch Brücken
            end

            -- Wander-Timer: zufaellig Richtung wechseln (kuerzere Intervalle in hoeherem Level)
            e.wanderTimer = (e.wanderTimer or 2) - dt
            if e.wanderTimer <= 0 then
                e.dir         = -((e.dir or 1))
                local wMin = S.WANDER_MIN or 0.8
                local wMax = S.WANDER_MAX or 3.0
                e.wanderTimer = wMin + math.random() * (wMax - wMin)
            end

            local gapToExit = e.ring - 1
            if gapToExit < 1 then
                -- Aeusserster Ring: patrouillieren statt stehen bleiben
                local dir  = e.dir or 1
                local step = (e.speed or S.ENEMY_SPEED) * dt
                local newAngle = (e.angle + dir * step) % 360
                local seg = S.RINGS[1] and S.RINGS[1].segs[e.seg or 1]
                if seg then
                    local clamped = clampToSeg(1, seg, newAngle)
                    local dd = math.abs(((clamped - newAngle + 180) % 360) - 180)
                    if dd > 0.5 then
                        -- Segment-Ende: Richtung umkehren, sofort kurzen Wander-Timer setzen
                        e.dir         = -dir
                        e.wanderTimer = math.random() * 1.5 + 0.3
                        newAngle      = e.angle
                    else
                        newAngle = clamped
                    end
                end
                e.angle = newAngle
                goto continueEnemyLoop
            else
                local allBridges = getBridgesOnGap(gapToExit)
                local curSeg = S.RINGS[e.ring].segs[e.seg or 1]
                -- Beste Bruecke insgesamt + beste in aktueller Richtung
                local bestAng, bestDist, bestSlot     = nil, 361, gapToExit
                local dirAng,  dirDist,  dirSlot      = nil, 361, gapToExit
                for _, b in ipairs(allBridges) do
                    local fullyOpen = (not b.state) or (b.state.state == 'open')
                    fullyOpen = fullyOpen and not guardianBlocksBridge(b.angle)
                    if fullyOpen then
                        if curSeg and not angleInSeg(e.ring, curSeg, b.angle) then
                            goto skipBridge
                        end
                        local targetOk = false
                        for _, ts in ipairs(S.RINGS[gapToExit].segs) do
                            if angleInSeg(gapToExit, ts, b.angle) then targetOk = true; break end
                        end
                        if not targetOk then goto skipBridge end
                        local d    = angleDist(e.angle, b.angle)
                        local sdiff = ((b.angle - e.angle + 180) % 360) - 180
                        if d < bestDist then bestDist=d; bestAng=b.angle; bestSlot=b.slot end
                        -- Bruecke in aktueller Bewegungsrichtung bevorzugen
                        if sdiff * (e.dir or 1) > 0 and d < dirDist then
                            dirDist=d; dirAng=b.angle; dirSlot=b.slot
                        end
                        ::skipBridge::
                    end
                end
                -- Richtungs-Bruecke bevorzugen, Fallback auf naechste
                local chosenAng  = dirAng  or bestAng
                local chosenSlot = dirSlot or bestSlot
                if chosenAng then
                    local diff = ((chosenAng - e.angle + 180) % 360) - 180
                    local step = (e.speed or S.ENEMY_SPEED) * dt
                    if math.abs(diff) <= step then
                        local stillOpen = false
                        for _, b in ipairs(allBridges) do
                            local fullyOpen2 = (not b.state) or (b.state.state == 'open')
                            if fullyOpen2 and not guardianBlocksBridge(b.angle) and b.slot == chosenSlot and angleDist(b.angle, chosenAng) < 2 then
                                stillOpen = true; break
                            end
                        end
                        if stillOpen then
                            e.angle        = chosenAng
                            e.onGap        = true
                            e.gapIdx       = gapToExit
                            e.gapDir       = gapToExit
                            e.gapAngle     = chosenAng
                            e.gapT         = 1.0
                            e.gapDeltaSlot = chosenSlot
                        end
                    else
                        e.angle = (e.angle + (diff > 0 and step or -step)) % 360
                        local seg = S.RINGS[e.ring].segs[e.seg or 1]
                        if seg then e.angle = clampToSeg(e.ring, seg, e.angle) end
                    end
                end
            end
        end
        ::continueEnemyLoop::
    end

    

    -- Gegner-Gegner-Kollision
    local toRemove = {}
    for i = 1, #S.enemies do
        local a = S.enemies[i]
        if not a.spawning then
            local ax, ay
            if a.onGap and S.RINGS[a.gapDir] and S.RINGS[a.gapDir + 1] then
                ax, ay = entityPosOnGap(a.gapDir, a.gapT, a.gapAngle)
            else
                ax, ay = entityPos(a.ring, a.angle)
            end
            for j = i + 1, #S.enemies do
                local b = S.enemies[j]
                if not b.spawning then
                    local bx, by
                    if b.onGap and S.RINGS[b.gapDir] and S.RINGS[b.gapDir + 1] then
                        bx, by = entityPosOnGap(b.gapDir, b.gapT, b.gapAngle)
                    else
                        bx, by = entityPos(b.ring, b.angle)
                    end
                    if math.abs(ax - bx) < 10 and math.abs(ay - by) < 10 then
                        toRemove[i] = true; toRemove[j] = true
                        sfxEnemyCollide()
                        local mx, my = (ax + bx) * 0.5, (ay + by) * 0.5
                        for k = 1, 14 do
                            local ang = (k / 14) * math.pi * 2
                            local r   = 5 + math.random() * 8
                            table.insert(S.burstParticles, {
                                x=mx + math.cos(ang)*r, y=my + math.sin(ang)*r,
                                life=S.TRAIL_LIFE * 3, maxLife=S.TRAIL_LIFE * 3
                            })
                        end
                    end
                end
            end
        end
    end
    local kept = {}
    for i, e in ipairs(S.enemies) do
        if not toRemove[i] then kept[#kept+1] = e end
    end
    S.enemies = kept
end

-- ---------------------------------------------------------------------------
function updateCollision()
    for killerIdx, e in ipairs(S.enemies) do
        if e.spawning then goto continue end
        local epx, epy
        if e.onGap then
            local g = e.gapDir
            if S.RINGS[g] and S.RINGS[g + 1] then
                epx, epy = entityPosOnGap(g, e.gapT, e.gapAngle)
            else
                epx, epy = entityPos(e.ring, e.angle)
            end
        else
            epx, epy = entityPos(e.ring, e.angle)
        end
        if math.abs(S.ppx - epx) < 8 and math.abs(S.ppy - epy) < 8 then
            -- Unverwundbarkeit pruefen
            if (S.playerHitTimer or 0) > 0 then goto continue end

            -- Killer-Gegner zuerst entfernen (vor retreatQueue, damit Index stimmt)
            table.remove(S.enemies, killerIdx)
            S.hitFlashTimer = 0.5  -- 3 schwarze Blitze
            sfxHit()

            if S.playerRing > 1 then
                local retreated = retreatQueue()
                if retreated then
                    S.playerSeg = findSeg(S.playerRing, S.playerAngle)
                else
                    S.playerRing = S.playerRing - 1
                    S.playerSeg  = findSeg(S.playerRing, S.playerAngle)
                end
                S.scrolling      = false
                S.transiting     = false
                S.playerHitTimer = S.HIT_INVINCIBLE
                S.ppx, S.ppy     = entityPos(S.playerRing, S.playerAngle)
            else
                -- Aeusserster Ring: nur Unverwundbarkeit, kein Tod
                S.playerHitTimer = S.HIT_INVINCIBLE
            end
            -- Burst-Partikel
            for k = 1, 10 do
                local ang = (k / 10) * math.pi * 2
                local r   = 4 + math.random() * 6
                table.insert(S.burstParticles, {
                    x=epx + math.cos(ang)*r, y=epy + math.sin(ang)*r,
                    life=S.TRAIL_LIFE * 3, maxLife=S.TRAIL_LIFE * 3
                })
            end
            break
        end
        ::continue::
    end
end

-- ---------------------------------------------------------------------------
function updateEnemyTrails(dt)
    for i = #S.burstParticles, 1, -1 do
        S.burstParticles[i].life = S.burstParticles[i].life - dt
        if S.burstParticles[i].life <= 0 then table.remove(S.burstParticles, i) end
    end
    for i = #S.enemyParticles, 1, -1 do
        S.enemyParticles[i].life = S.enemyParticles[i].life - dt
        if S.enemyParticles[i].life <= 0 then table.remove(S.enemyParticles, i) end
    end
    for _, e in ipairs(S.enemies) do
        if e.spawning then goto skipTrail end
        do
            local px, py
            if e.onGap then
                local g = e.gapDir
                if S.RINGS[g] and S.RINGS[g + 1] then
                    px, py = entityPosOnGap(g, e.gapT, e.gapAngle)
                else
                    px, py = entityPos(e.ring, e.angle)
                end
            else
                px, py = entityPos(e.ring, e.angle)
            end
            table.insert(S.enemyParticles, {x=px, y=py, life=S.TRAIL_LIFE})
            if #S.enemyParticles > 120 then table.remove(S.enemyParticles, 1) end
        end
        ::skipTrail::
    end
end

-- ---------------------------------------------------------------------------
function respawnPlayer()
    S.enemies           = S.savedEnemies or {}
    S.savedEnemies      = nil
    S.enemyFreezeTimer  = 1.0   -- Gegner 1 Sekunde einfrieren nach Respawn
    S.spawnTimer        = 1.5
    S.transiting     = false
    S.scrolling      = false
    S.scrollT        = 0.0
    S.particles      = {}
    S.playerHistory  = {}
    S.shatterPieces  = {}
    S.enemyParticles = {}
    S.burstParticles = {}
    -- An Sterbeposition respawnen
    S.playerRing     = S.deathRing  or 1
    S.playerSeg      = S.deathSeg   or 1
    S.playerAngle    = S.deathAngle or 0.0
    S.zoom           = S.deathZoom  or 1.3
    S.zoomTarget     = S.zoom
    S.aBufTimer      = 0
    S.bBufTimer      = 0
    S.playerHitTimer = 1.0   -- kurze Unverwundbarkeit nach Respawn
    S.gameState      = S.STATE_PLAY
    S.deadTimer      = 0.0
end

function setupLevel(lvl)
    -- Level-spezifische Schwierigkeit
    if lvl == 1 then
        S.RING_QUEUE_ALL    = S.RING_QUEUE_L1
        S.SPAWN_INTERVAL    = 2.5
        S.ENEMY_SPEED_MIN   = 50
        S.ENEMY_SPEED_MAX   = 80
        S.ENEMY_MAX         = 8
        S.WANDER_MIN        = 0.8
        S.WANDER_MAX        = 3.0
        S.BRIDGE_OPEN_DUR   = 3.5
        S.BRIDGE_CLOSED_DUR = 3.5
    elseif lvl == 2 then
        S.RING_QUEUE_ALL    = S.RING_QUEUE_L2
        S.SPAWN_INTERVAL    = 0.9
        S.ENEMY_SPEED_MIN   = 50
        S.ENEMY_SPEED_MAX   = 85
        S.ENEMY_MAX         = 18
        S.WANDER_MIN        = 0.4
        S.WANDER_MAX        = 1.6
        S.BRIDGE_OPEN_DUR   = 2.0
        S.BRIDGE_CLOSED_DUR = 4.5
    else
        S.RING_QUEUE_ALL    = S.RING_QUEUE_L3
        S.SPAWN_INTERVAL    = 0.6
        S.ENEMY_SPEED_MIN   = 70
        S.ENEMY_SPEED_MAX   = 115
        S.ENEMY_MAX         = 28
        S.WANDER_MIN        = 0.2
        S.WANDER_MAX        = 0.9
        S.BRIDGE_OPEN_DUR   = 1.5
        S.BRIDGE_CLOSED_DUR = 5.5
    end
    S.TOTAL_RINGS = #S.RING_QUEUE_ALL
    S.enemies        = {}
    S.spawnTimer     = 1.5
    S.playerHitTimer = 0
    S.transiting     = false
    S.scrolling      = false
    S.scrollT        = 0.0
    S.zoom           = 1.3
    S.zoomTarget     = 1.3
    S.aBufTimer      = 0
    S.bBufTimer      = 0
    S.particles      = {}
    S.playerHistory  = {}
    S.shatterPieces  = {}
    S.enemyParticles = {}
    S.burstParticles = {}

    S.queueHead     = 1
    S.ringsCleared  = 0
    S.queueAdvances = 0
    S.finalStage    = false
    S.conceptualRing = 1
    S.RING_COUNT    = 3   -- immer 3 Ringe sichtbar
    rebuildRingsFromQueue()

    S.angles     = {}
    S.ringDeltas = {}
    for i = 1, S.RING_COUNT do
        local rot = S.RINGS[i].rot
        S.angles[i]          = (rot and rot.startAngle) or 0
        S.ringDeltas[i]      = 0
        S.RINGS[i]._rotState = nil
    end

    S.bStates    = {}
    S.bStates_up = {}
    for slot = 1, S.RING_COUNT do
        initBStates(slot)
    end

    S.playerRing  = 1
    S.playerSeg   = 1
    S.playerAngle = 0.0
end

function resetGame()
    S.lives     = S.maxLives
    S.level     = 1
    setupLevel(S.level)
    S.gameState = S.STATE_PLAY
end
