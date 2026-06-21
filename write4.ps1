$enc = [System.Text.UTF8Encoding]::new($false)
$src = "C:\Users\User\Downloads\playdate-master\playdate-master\source"

function wf($n, $c) { [System.IO.File]::WriteAllText("$src\$n", $c, $enc) }

# ============================================================================
# model.lua - 8 fixed rings, no queue
# ============================================================================
wf "model.lua" @"
-- model.lua: 8 feste Ringe (kein Queue)
local math <const> = math
S = {}
S.cx = 200; S.cy = 120
S.RINGS = {
  -- 1 inner
  { mid=27, inner=24, outer=30, rot={dir=1,speed=26,pauseLen=0.6,startAngle=10,swingPts={10,75,40,110,55}}, segs={{arcW=60,startOff=0,bOff={30},closeable={true},bOff_up={30},closeable_up={true}},{arcW=60,startOff=72,bOff={},closeable={},bOff_up={},closeable_up={}},{arcW=60,startOff=144,bOff={30},closeable={true},bOff_up={30},closeable_up={true}},{arcW=60,startOff=216,bOff={30},closeable={true},bOff_up={30},closeable_up={true}},{arcW=60,startOff=288,bOff={},closeable={},bOff_up={},closeable_up={}}} },
  -- 2 full circle
  { mid=34, inner=31, outer=37, rot={dir=1,speed=36,pauseLen=0.25,startAngle=0}, segs={{arcW=360,startOff=0,bOff={},closeable={},bOff_up={},closeable_up={}}} },
  -- 3 4 segs 2 bridges
  { mid=41, inner=37, outer=45, rot={dir=-1,speed=30,pauseLen=0.4,startAngle=20,swingPts={20,90,50,130}}, segs={{arcW=65,startOff=0,bOff={30},closeable={true},bOff_up={30},closeable_up={true}},{arcW=45,startOff=110,bOff={},closeable={},bOff_up={},closeable_up={}},{arcW=65,startOff=200,bOff={30},closeable={true},bOff_up={30},closeable_up={true}},{arcW=50,startOff=300,bOff={},closeable={},bOff_up={},closeable_up={}}} },
  -- 4 full circle
  { mid=48, inner=44, outer=52, rot={dir=1,speed=7,pauseLen=1.5,startAngle=0}, segs={{arcW=360,startOff=0,bOff={},closeable={},bOff_up={},closeable_up={}}} },
  -- 5 2 segs 2 bridges
  { mid=56, inner=51, outer=61, rot={dir=1,speed=22,pauseLen=0.8,startAngle=30,swingPts={30,100,60}}, segs={{arcW=120,startOff=0,bOff={50},closeable={true},bOff_up={50},closeable_up={true}},{arcW=120,startOff=150,bOff={50},closeable={true},bOff_up={50},closeable_up={true}}} },
  -- 6 full circle
  { mid=64, inner=58, outer=70, rot={dir=1,speed=14,pauseLen=0.6,startAngle=60}, segs={{arcW=360,startOff=0,bOff={},closeable={},bOff_up={},closeable_up={}}} },
  -- 7 6 segs 3 bridges
  { mid=73, inner=66, outer=80, rot={dir=-1,speed=16,pauseLen=1.0,startAngle=15,swingPts={15,90,45,135}}, segs={{arcW=50,startOff=0,bOff={25},closeable={true},bOff_up={25},closeable_up={true}},{arcW=50,startOff=60,bOff={},closeable={},bOff_up={},closeable_up={}},{arcW=50,startOff=120,bOff={},closeable={},bOff_up={},closeable_up={}},{arcW=50,startOff=180,bOff={25},closeable={true},bOff_up={25},closeable_up={true}},{arcW=50,startOff=240,bOff={},closeable={},bOff_up={},closeable_up={}},{arcW=50,startOff=300,bOff={25},closeable={true},bOff_up={25},closeable_up={true}}} },
  -- 8 outer/start - full circle no bridges
  { mid=83, inner=75, outer=91, rot={dir=1,speed=11,pauseLen=0.4,startAngle=0}, segs={{arcW=360,startOff=0,bOff={},closeable={},bOff_up={},closeable_up={}}} },
}
S.RING_COUNT = 8; S.CENTER_R = 10
S.BRIDGE_OPEN_DUR=2.5; S.BRIDGE_CLOSE_T=0.4; S.BRIDGE_CLOSED_DUR=4.0; S.BRIDGE_OPEN_T=0.4; S.BRIDGE_WARN=0.5; S.BRIDGE_HALF=14; S.BRIDGE_HALF_BACK=22
S.zoom=0; S.zoomTarget=0; S.angles={}; S.ringDeltas={}; S.bStates={}; S.bStates_up={}
S.playerRing=8; S.playerSeg=1; S.playerAngle=0; S.transiting=false; S.transDir=0; S.transT=0; S.transAngle=0; S.TRANS_TIME=0.2; S.ppx=0; S.ppy=0
S.enemies={}; S.ENEMY_SPEED_MIN=24; S.ENEMY_SPEED_MAX=72; S.ENEMY_MAX=4; S.ENEMY_GAP_SPD=3; S.spawnTimer=1.5; S.SPAWN_INTERVAL=3.5; S.ESCAPE_TIME=0.45; S.enemyFreezeTimer=0
S.aBufTimer=0; S.bBufTimer=0; S.BUF_TIME=0.3
S.STATE_PLAY='play'; S.STATE_DEAD='dead'; S.STATE_IMPLODE='implode'; S.STATE_GAMEOVER='gameover'; S.STATE_WIN='win'; S.STATE_TITLE='title'
S.titleMenuIdx=1; S.titleCrankAcc=0; S.titleAnim='idle'; S.titleAnimT=0; S.titleCircleT=0; S.TITLE_CIRCLE_DUR=1.2; S.TITLE_SLIDE_DUR=0.55; S.TITLE_FILL_DUR=0.5; S.TITLE_ZOOM_DUR=0.65; S.gameState='play'
S.deadTimer=0; S.DEAD_HOLD=2; S.playerHitTimer=0; S.HIT_INVINCIBLE=1.5; S.hitFlashTimer=0; S.implodeT=0; S.IMPLODE_DUR=1.8; S.lives=3; S.maxLives=3; S.implodeBaseZoom=0; S.implodeCache=nil
S.particles={}; S.TRAIL_LIFE=0.25; S.playerHistory={}; S.HISTORY_MAX=4; S.shatterPieces={}; S.enemyParticles={}; S.burstParticles={}; S.enemyRotation=0; S.lastMs=0
function sc(r) return r*S.zoom end
function angleDist(a,b) return math.abs(((a-b+180)%360)-180) end
function segArcStart(si,s) local d=S.angles[si]; return (d+s.startOff-s.arcW*0.5)%360 end
function angleInSeg(si,s,wa) if s.arcW>=360 then return true end; local as=segArcStart(si,s); return ((wa-as)%360)<=s.arcW end
function clampToSeg(si,s,wa) if s.arcW>=360 then return wa%360 end; local as=segArcStart(si,s); local ae=(as+s.arcW)%360; if((wa-as)%360)<=s.arcW then return wa%360 end; if angleDist(wa,as)<=angleDist(wa,ae) then return as else return ae end end
function segBridgeAnglesFrom(si,s,bl) local as=segArcStart(si,s); local o={}; for _,v in ipairs(bl) do o[#o+1]=(as+v)%360 end; return o end
function nearBridge(ri,wa,tol) tol=tol or S.BRIDGE_HALF; local r=S.RINGS[ri]; for si,s in ipairs(r.segs) do for _,ba in ipairs(segBridgeAnglesFrom(ri,s,s.bOff)) do if math.abs(angleDist(wa,ba))<=tol then return true,ba end end end; return false end
function findSeg(si,wa) local r=S.RINGS[si]; for i,s in ipairs(r.segs) do if angleInSeg(si,s,wa) then return i end end; local bi,bd=1,361; for i,s in ipairs(r.segs) do local as=segArcStart(si,s); local ae=(as+s.arcW)%360; local d=math.min(angleDist(wa,as),angleDist(wa,ae)); if d<bd then bd=d; bi=i end end; return bi end
function entityPos(ri,a) local r=sc(S.RINGS[ri].mid); local ra=math.rad(a); return S.cx+r*math.sin(ra),S.cy-r*math.cos(ra) end
function entityPosOnGap(gi,t,a) local r1=sc(S.RINGS[gi].mid); local r2=sc(S.RINGS[gi+1].mid); local r=r1+(r2-r1)*t; local ra=math.rad(a); return S.cx+r*math.sin(ra),S.cy-r*math.cos(ra) end
function getBridgesOnGap(ri) local o={}; local r=S.RINGS[ri]; for si,s in ipairs(r.segs) do for _,ba in ipairs(segBridgeAnglesFrom(ri,s,s.bOff)) do o[#o+1]={ring=ri,seg=si,angle=ba} end end; return o end
"@

# ============================================================================
# controller.lua - fixed rings, no queues
# ============================================================================
wf "controller.lua" @"
-- controller.lua: update/setup for 8 fixed rings
local math <const> = math

-- ---------------------------------------------------------------------------
local function makeBridgeStates(seg)
    local states = {}
    for i, cl in ipairs(seg.closeable) do
        if cl then
            states[i] = { state='open', timer=S.BRIDGE_OPEN_DUR, t=1.0 }
        end
    end
    return states
end

local function makeBridgeStatesUp(seg)
    local states = {}
    for i, cl in ipairs(seg.closeable_up or {}) do
        if cl then
            states[i] = { state='open', timer=S.BRIDGE_OPEN_DUR, t=1.0 }
        end
    end
    return states
end

-- ---------------------------------------------------------------------------
function initBStates(slot)
    S.bStates[slot]    = {}
    S.bStates_up[slot] = {}
    for si, seg in ipairs(S.RINGS[slot].segs) do
        S.bStates[slot][si]    = makeBridgeStates(seg)
        S.bStates_up[slot][si] = makeBridgeStatesUp(seg)
    end
end

-- ---------------------------------------------------------------------------
function calcZoom()
    local idx = math.min(8, math.max(1, S.playerRing + 2))
    S.zoomTarget = 115 / S.RINGS[idx].outer
    if S.zoom == 0 then S.zoom = S.zoomTarget end
end

-- ---------------------------------------------------------------------------
function updateBridges(dt)
    for slot = 1, S.RING_COUNT do
        local rot = S.RINGS[slot].rot
        local oldAngle = S.angles[slot]
        if rot and rot.speed > 0 then
            local bm = S.RINGS[slot]._rotState
            if not bm then
                bm = { t=0, paused=false, pauseT=0, swingIdx=1, pauseEvery=2.0 }
                S.RINGS[slot]._rotState = bm
            end
            if rot.swingPts then
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
                    local step = rot.speed * dt
                    if math.abs(diff) <= step + 0.5 then
                        S.angles[slot] = tgt % 360
                        bm.paused  = true; bm.pauseT = 0
                    else
                        S.angles[slot] = (cur + (diff > 0 and 1 or -1) * step) % 360
                    end
                end
            else
                if bm.paused then
                    bm.pauseT = bm.pauseT + dt
                    if bm.pauseT >= rot.pauseLen then bm.paused=false; bm.pauseT=0 end
                else
                    S.angles[slot] = (S.angles[slot] + rot.dir * rot.speed * dt) % 360
                    bm.t = bm.t + dt
                    if bm.t >= bm.pauseEvery then bm.paused=true; bm.t=0 end
                end
            end
        end
        S.ringDeltas[slot] = ((S.angles[slot] - oldAngle + 180) % 360) - 180
    end

    -- Bridge state machines
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
                            bs.t = math.max(0, bs.timer / S.BRIDGE_CLOSE_T)
                            if bs.timer <= 0 then bs.state='closed'; bs.t=0; bs.timer=S.BRIDGE_CLOSED_DUR end
                        elseif bs.state == 'closed' then
                            bs.timer = bs.timer - dt
                            if bs.timer <= 0 then bs.state='opening'; bs.timer=S.BRIDGE_OPEN_T end
                        elseif bs.state == 'opening' then
                            bs.timer = bs.timer - dt
                            bs.t = math.max(0, 1.0 - bs.timer / S.BRIDGE_OPEN_T)
                            if bs.timer <= 0 then bs.state='open'; bs.t=1.0; bs.timer=S.BRIDGE_OPEN_DUR end
                        end
                    end
                end
            end
        end
    end
    -- up-bridge state machines
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
                            bs.t = math.max(0, bs.timer / S.BRIDGE_CLOSE_T)
                            if bs.timer <= 0 then bs.state='closed'; bs.t=0; bs.timer=S.BRIDGE_CLOSED_DUR end
                        elseif bs.state == 'closed' then
                            bs.timer = bs.timer - dt
                            if bs.timer <= 0 then bs.state='opening'; bs.timer=S.BRIDGE_OPEN_T end
                        elseif bs.state == 'opening' then
                            bs.timer = bs.timer - dt
                            bs.t = math.max(0, 1.0 - bs.timer / S.BRIDGE_OPEN_T)
                            if bs.timer <= 0 then bs.state='open'; bs.t=1.0; bs.timer=S.BRIDGE_OPEN_DUR end
                        end
                    end
                end
            end
        end
    end

    -- Carry player / enemies with ring rotation
    if not S.transiting then
        S.playerAngle = (S.playerAngle + S.ringDeltas[S.playerRing]) % 360
    end
    for _, e in ipairs(S.enemies) do
        if not e.onGap then
            e.angle = (e.angle + S.ringDeltas[e.ring]) % 360
            if not e.spawning then
                e.seg = findSeg(e.ring, e.angle)
                local seg = S.RINGS[e.ring].segs[e.seg]
                if seg then e.angle = clampToSeg(e.ring, seg, e.angle) end
            end
        end
    end
end

-- ---------------------------------------------------------------------------
function updatePlayer(dt)
    S.playerHitTimer = math.max(0, (S.playerHitTimer or 0) - dt)
    calcZoom()
    S.zoom = S.zoom + (S.zoomTarget - S.zoom) * dt * 3

    if playdate.buttonJustPressed(playdate.kButtonA) then S.aBufTimer = S.BUF_TIME end
    if playdate.buttonJustPressed(playdate.kButtonB) then S.bBufTimer = S.BUF_TIME end

    if not S.transiting then
        S.playerAngle = (S.playerAngle + playdate.getCrankChange()) % 360
        local seg = S.RINGS[S.playerRing].segs[S.playerSeg]
        if seg then S.playerAngle = clampToSeg(S.playerRing, seg, S.playerAngle) end

        -- A: move inward (playerRing - 1)
        if S.aBufTimer > 0 and S.playerRing > 1 then
            local ok, ba = nearBridge(S.playerRing - 1, S.playerAngle)
            if ok then
                S.transiting=true; S.transDir=-1; S.transT=0; S.transAngle=ba
                S.aBufTimer=0
            end
        end
        S.aBufTimer = math.max(0, S.aBufTimer - dt)

        -- B: move outward (playerRing + 1)
        if S.bBufTimer > 0 and S.playerRing < S.RING_COUNT then
            local ok, ba = nearBridge(S.playerRing, S.playerAngle, S.BRIDGE_HALF_BACK)
            if ok then
                S.transiting=true; S.transDir=1; S.transT=0; S.transAngle=ba
                S.bBufTimer=0
            end
        end
        S.bBufTimer = math.max(0, S.bBufTimer - dt)
    else
        S.transT = S.transT + dt / S.TRANS_TIME
        if S.transT >= 1.0 then
            if S.transDir == -1 then
                if S.playerRing == 1 then
                    S.gameState = S.STATE_IMPLODE
                    S.implodeT = 0.0
                    S.implodeBaseZoom = S.zoom
                    S.transiting = false
                    return
                else
                    S.playerRing = S.playerRing - 1
                end
            else
                S.playerRing = math.min(S.RING_COUNT, S.playerRing + 1)
            end
            S.playerAngle = S.transAngle
            S.playerSeg = findSeg(S.playerRing, S.playerAngle)
            S.transiting = false
            S.transT = 1.0
        end
    end

    if S.transiting then
        local toRing = math.max(1, math.min(S.RING_COUNT, S.playerRing + S.transDir))
        local r1 = sc(S.RINGS[S.playerRing].mid)
        local r2 = sc(S.RINGS[toRing].mid)
        local r = r1 + (r2 - r1) * S.transT
        local a = math.rad(S.transAngle)
        S.ppx = S.cx + r * math.sin(a)
        S.ppy = S.cy - r * math.cos(a)
    else
        S.ppx, S.ppy = entityPos(S.playerRing, S.playerAngle)
    end

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
local function guardianBlocksBridge(angleDeg)
    for _, e in ipairs(S.enemies) do
        if e.type == 'guardian' and not e.spawning and math.abs(e.ring - S.playerRing) <= 1 then
            if angleDist(e.angle, angleDeg) < 15 then return true end
        end
    end
    return false
end

-- ---------------------------------------------------------------------------
function updateEnemies(dt)
    S.enemyRotation = (S.enemyRotation + 90 * dt) % 360
    if S.enemyFreezeTimer > 0 then
        S.enemyFreezeTimer = S.enemyFreezeTimer - dt
        return
    end
    S.spawnTimer = S.spawnTimer - dt
    if S.spawnTimer <= 0 then
        S.spawnTimer = S.SPAWN_INTERVAL
        local allB = getBridgesOnGap(S.RING_COUNT)
        if #allB > 0 and #S.enemies < S.ENEMY_MAX then
            local b = allB[math.random(1, #allB)]
            local si = findSeg(S.RING_COUNT, b.angle)
            local etype = 'ghost'
            local r = math.random()
            if r < 0.3 then etype = 'hunter'
            elseif r < 0.5 then etype = 'guardian' end
            table.insert(S.enemies, {
                ring=S.RING_COUNT, seg=si, angle=b.angle % 360,
                onGap=false, gapDir=0, gapAngle=b.angle, gapT=0, gapIdx=0,
                spawning=true, spawnT=0.0,
                speed = S.ENEMY_SPEED_MIN + math.random() * (S.ENEMY_SPEED_MAX - S.ENEMY_SPEED_MIN),
                dir = (math.random(2) == 1) and 1 or -1,
                wanderTimer = 0.8 + math.random() * 2.2,
                type = etype,
            })
        else
            S.spawnTimer = 0.5
        end
    end

    for idx = #S.enemies, 1, -1 do
        local e = S.enemies[idx]
        if e.spawning then
            e.spawnT = e.spawnT + dt / 0.5
            if e.spawnT >= 1.0 then e.spawning = false; e.spawnT = 1.0 end
        elseif e.onGap then
            e.gapAngle = (e.gapAngle + S.ringDeltas[e.gapDeltaSlot or e.gapIdx or e.ring]) % 360
            e.gapT = e.gapT - dt * S.ENEMY_GAP_SPD
            if e.gapT <= 0.0 then
                e.onGap = false
                e.ring = e.gapDir
                e.angle = e.gapAngle
                e.seg = findSeg(e.ring, e.angle)
                local arrSeg = S.RINGS[e.ring].segs[e.seg]
                if arrSeg then e.angle = clampToSeg(e.ring, arrSeg, e.angle) end
                e.gapT = 0.0
            end
        else
            e.wanderTimer = (e.wanderTimer or 2) - dt
            if e.wanderTimer <= 0 then
                e.dir = -(e.dir or 1)
                e.wanderTimer = 0.8 + math.random() * 2.2
            end
            local gapToExit = e.ring - 1
            if gapToExit < 1 then
                local dir = e.dir or 1
                local step = (e.speed or S.ENEMY_SPEED_MIN) * dt
                local newAngle = (e.angle + dir * step) % 360
                local seg = S.RINGS[1].segs[e.seg or 1]
                if seg then
                    local clamped = clampToSeg(1, seg, newAngle)
                    local dd = math.abs(((clamped - newAngle + 180) % 360) - 180)
                    if dd > 0.5 then
                        e.dir = -dir
                        e.wanderTimer = math.random() * 1.5 + 0.3
                        newAngle = e.angle
                    else
                        newAngle = clamped
                    end
                end
                e.angle = newAngle
                goto continueEnemy
            else
                local allBridges = getBridgesOnGap(gapToExit)
                local curSeg = S.RINGS[e.ring].segs[e.seg or 1]
                local bestAng, bestDist = nil, 361
                local dirAng, dirDist = nil, 361
                for _, b in ipairs(allBridges) do
                    local fullyOpen = not guardianBlocksBridge(b.angle)
                    if fullyOpen then
                        if curSeg and not angleInSeg(e.ring, curSeg, b.angle) then goto skipB end
                        local targetOk = false
                        for _, ts in ipairs(S.RINGS[gapToExit].segs) do
                            if angleInSeg(gapToExit, ts, b.angle) then targetOk = true; break end
                        end
                        if not targetOk then goto skipB end
                        local d = angleDist(e.angle, b.angle)
                        local sdiff = ((b.angle - e.angle + 180) % 360) - 180
                        if d < bestDist then bestDist=d; bestAng=b.angle end
                        if sdiff * (e.dir or 1) > 0 and d < dirDist then dirDist=d; dirAng=b.angle end
                        ::skipB::
                    end
                end
                local chosenAng = dirAng or bestAng
                if chosenAng then
                    local diff = ((chosenAng - e.angle + 180) % 360) - 180
                    local step = (e.speed or S.ENEMY_SPEED_MIN) * dt
                    if math.abs(diff) <= step then
                        e.angle = chosenAng
                        e.onGap = true
                        e.gapIdx = gapToExit
                        e.gapDir = gapToExit
                        e.gapAngle = chosenAng
                        e.gapT = 1.0
                        e.gapDeltaSlot = gapToExit
                    else
                        e.angle = (e.angle + (diff > 0 and step or -step)) % 360
                        local seg = S.RINGS[e.ring].segs[e.seg or 1]
                        if seg then e.angle = clampToSeg(e.ring, seg, e.angle) end
                    end
                end
            end
        end
        ::continueEnemy::
    end
end

-- ---------------------------------------------------------------------------
function updateCollision()
    for killerIdx, e in ipairs(S.enemies) do
        if e.spawning then goto continue end
        local epx, epy
        if e.onGap then
            local g = e.gapDir
            if S.RINGS[g] and S.RINGS[g+1] then
                epx, epy = entityPosOnGap(g, e.gapT, e.gapAngle)
            else
                epx, epy = entityPos(e.ring, e.angle)
            end
        else
            epx, epy = entityPos(e.ring, e.angle)
        end
        if math.abs(S.ppx - epx) < 8 and math.abs(S.ppy - epy) < 8 then
            if (S.playerHitTimer or 0) > 0 then goto continue end
            table.remove(S.enemies, killerIdx)
            S.hitFlashTimer = 0.5
            -- Push outward: playerRing + 1
            if S.playerRing < S.RING_COUNT then
                S.playerRing = S.playerRing + 1
                S.playerSeg = findSeg(S.playerRing, S.playerAngle)
            end
            S.transiting = false
            S.playerHitTimer = S.HIT_INVINCIBLE
            S.ppx, S.ppy = entityPos(S.playerRing, S.playerAngle)
            for k = 1, 10 do
                local ang = (k / 10) * math.pi * 2
                local r = 4 + math.random() * 6
                table.insert(S.burstParticles, {
                    x=epx+math.cos(ang)*r, y=epy+math.sin(ang)*r,
                    life=S.TRAIL_LIFE*3, maxLife=S.TRAIL_LIFE*3
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
        if e.spawning then goto skipT end
        local px, py
        if e.onGap then
            local g = e.gapDir
            if S.RINGS[g] and S.RINGS[g+1] then px, py = entityPosOnGap(g, e.gapT, e.gapAngle)
            else px, py = entityPos(e.ring, e.angle) end
        else
            px, py = entityPos(e.ring, e.angle)
        end
        table.insert(S.enemyParticles, {x=px, y=py, life=S.TRAIL_LIFE})
        if #S.enemyParticles > 120 then table.remove(S.enemyParticles, 1) end
        ::skipT::
    end
end

-- ---------------------------------------------------------------------------
function respawnPlayer()
    S.enemies = S.savedEnemies or {}
    S.savedEnemies = nil
    S.enemyFreezeTimer = 1.0
    S.spawnTimer = 1.5
    S.transiting = false
    S.particles = {}
    S.playerHistory = {}
    S.shatterPieces = {}
    S.enemyParticles = {}
    S.burstParticles = {}
    S.playerRing = S.deathRing or S.RING_COUNT
    S.playerSeg = S.deathSeg or 1
    S.playerAngle = S.deathAngle or 0.0
    S.zoom = S.deathZoom or (115 / S.RINGS[math.min(8, S.RING_COUNT)].outer)
    S.zoomTarget = S.zoom
    S.aBufTimer = 0
    S.bBufTimer = 0
    S.playerHitTimer = 1.0
    S.gameState = S.STATE_PLAY
    S.deadTimer = 0.0
end

-- ---------------------------------------------------------------------------
function setupLevel()
    S.enemies = {}
    S.spawnTimer = 1.5
    S.playerHitTimer = 0
    S.transiting = false
    calcZoom()
    S.zoom = S.zoomTarget
    S.aBufTimer = 0
    S.bBufTimer = 0
    S.particles = {}
    S.playerHistory = {}
    S.shatterPieces = {}
    S.enemyParticles = {}
    S.burstParticles = {}

    S.angles = {}
    S.ringDeltas = {}
    for i = 1, S.RING_COUNT do
        local rot = S.RINGS[i].rot
        S.angles[i] = (rot and rot.startAngle) or 0
        S.ringDeltas[i] = 0
        S.RINGS[i]._rotState = nil
    end

    S.bStates = {}
    S.bStates_up = {}
    for slot = 1, S.RING_COUNT do
        initBStates(slot)
    end

    S.playerRing = S.RING_COUNT
    S.playerSeg = 1
    S.playerAngle = 0.0
end

function resetGame()
    S.lives = S.maxLives
    setupLevel()
    S.gameState = S.STATE_PLAY
end
"@

# ============================================================================
# view.lua - draw only 3 rings around playerRing, fillEllipseInRect for arcs
# ============================================================================
wf "view.lua" @"
-- view.lua: drawing for 8 fixed rings
import "CoreLibs/graphics"
import "gfxp"

local gfx  <const> = playdate.graphics
local math <const> = math
local gfxp <const> = GFXP

-- Star background
local abstractBg = nil
local function buildAbstractBg()
    abstractBg = gfx.image.new(400, 240, gfx.kColorBlack)
    gfx.pushContext(abstractBg)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(0, 0, 400, 240)
        math.randomseed(42)
        for i = 1, 100 do
            local x = math.random(0, 399)
            local y = math.random(0, 239)
            local sz = math.random(1, 3)
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(x, y, sz, sz)
        end
        gfxp.set('gray-3')
        gfx.fillCircleAtPoint(55, 45, 20)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(62, 40, 17)
        gfxp.set('gray-1')
        gfx.fillCircleAtPoint(340, 55, 25)
        gfxp.set('gray-3')
        gfx.fillCircleAtPoint(55, 195, 15)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawLine(30, 188, 80, 202)
        gfx.drawLine(32, 192, 78, 198)
        gfx.drawLine(30, 202, 80, 188)
        gfx.drawLine(32, 198, 78, 192)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(200, 28, 6)
        gfxp.set('gray-5')
        gfx.fillCircleAtPoint(370, 150, 10)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(370, 150, 8)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(295, 210, 4)
        gfxp.set('white')
    gfx.popContext()
end

local function drawScanlineBg()
    if not abstractBg then buildAbstractBg() end
    abstractBg:draw(0, 0)
    gfx.setColor(gfx.kColorBlack)
end

-- Draw arc using fillEllipseInRect (inner/outer ellipse difference)
local function drawArc(innerR, outerR, arcStart, arcSweep)
    if arcSweep <= 0 then return end
    local cx = S.cx
    local cy = S.cy
    local oi = sc(innerR)
    local oo = sc(outerR)
    local w = oo * 2
    local h = oo * 2
    gfx.setColor(gfx.kColorWhite)
    gfx.fillEllipseInRect(cx - oo, cy - oo, w, h, arcStart, arcSweep)
    gfx.setColor(gfx.kColorBlack)
    local iw = oi * 2
    local ih = oi * 2
    gfx.fillEllipseInRect(cx - oi, cy - oi, iw, ih, arcStart, arcSweep)
end

local function drawBridgeShape(angle_deg, midR, halfLen, halfW)
    local angle = math.rad(angle_deg)
    local r = sc(midR)
    local bx = S.cx + r * math.sin(angle)
    local by = S.cy - r * math.cos(angle)
    local hh = halfLen * S.zoom
    local hw = halfW * S.zoom
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

-- Enemy sprites
local enemyImageGhost = nil
local enemyImageHunter = nil
local enemyImageGuardian = nil
local enemyImageDead = nil

local function initSprites()
    if enemyImageGhost then return end
    enemyImageGhost = gfx.image.new(32, 32, gfx.kColorClear)
    if enemyImageGhost then
        gfx.pushContext(enemyImageGhost)
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(5, 3, 22, 22)
            gfx.fillRect(7, 24, 4, 5)
            gfx.fillRect(12, 24, 5, 7)
            gfx.fillRect(17, 24, 4, 4)
            gfx.fillRect(21, 24, 4, 6)
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(6, 4, 20, 20)
            gfx.fillRect(8, 24, 2, 3)
            gfx.fillRect(13, 24, 3, 5)
            gfx.fillRect(18, 24, 2, 2)
            gfx.fillRect(22, 24, 2, 4)
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(10, 12, 3, 3)
            gfx.fillRect(19, 12, 3, 3)
        gfx.popContext()
    end
    enemyImageHunter = gfx.image.new(32, 32, gfx.kColorClear)
    if enemyImageHunter then
        gfx.pushContext(enemyImageHunter)
            gfx.setColor(gfx.kColorBlack)
            gfx.fillPolygon(16, 1, 1, 28, 31, 28)
            gfx.setColor(gfx.kColorWhite)
            gfx.fillPolygon(16, 4, 4, 25, 28, 25)
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(9, 14, 6, 2)
            gfx.fillRect(17, 14, 6, 2)
        gfx.popContext()
    end
    enemyImageGuardian = gfx.image.new(32, 32, gfx.kColorClear)
    if enemyImageGuardian then
        gfx.pushContext(enemyImageGuardian)
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(3, 3, 26, 26)
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(5, 5, 22, 22)
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(5, 13, 22, 4)
            gfx.fillRect(14, 5, 4, 22)
            gfx.fillRect(8, 7, 2, 2)
            gfx.fillRect(22, 7, 2, 2)
        gfx.popContext()
    end
    enemyImageDead = gfx.image.new(32, 32, gfx.kColorClear)
    if enemyImageDead then
        gfx.pushContext(enemyImageDead)
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(6, 4, 20, 2)
            gfx.fillRect(6, 22, 20, 2)
            gfx.fillRect(6, 4, 2, 20)
            gfx.fillRect(24, 4, 2, 20)
            gfx.fillRect(8, 24, 2, 3)
            gfx.fillRect(13, 24, 3, 5)
            gfx.fillRect(18, 24, 2, 2)
            gfx.fillRect(22, 24, 2, 4)
            gfx.fillRect(8, 10, 2, 2)
            gfx.fillRect(12, 10, 2, 2)
            gfx.fillRect(10, 12, 2, 2)
            gfx.fillRect(8, 14, 2, 2)
            gfx.fillRect(12, 14, 2, 2)
            gfx.fillRect(18, 10, 2, 2)
            gfx.fillRect(22, 10, 2, 2)
            gfx.fillRect(20, 12, 2, 2)
            gfx.fillRect(18, 14, 2, 2)
            gfx.fillRect(22, 14, 2, 2)
        gfx.popContext()
    end
end

local function drawEnemyAtAngle(px, py, hl, hw, angleDeg, etype)
    initSprites()
    local img
    if etype == 'hunter' then img = enemyImageHunter
    elseif etype == 'guardian' then img = enemyImageGuardian
    else img = enemyImageGhost end
    if not img then return end
    local scale = math.max(hw / 14.0, 0.25)
    gfx.setImageDrawMode(gfx.kDrawModeInverted)
    img:drawRotated(math.floor(px), math.floor(py), angleDeg, scale)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

-- Draw only 3 rings around playerRing (playerRing+2 down to playerRing)
function drawBoard()
    drawScanlineBg()
    local nowMs = playdate.getCurrentTimeMilliseconds()

    local ringStart = math.max(1, S.playerRing - 2)
    local ringEnd   = math.min(S.RING_COUNT, S.playerRing + 2)

    for slot = ringStart, ringEnd do
        local ring = S.RINGS[slot]
        local depth = 1.0 - (slot - ringStart) / math.max(1, ringEnd - ringStart) * 0.55
        local mid = (ring.inner + ring.outer) * 0.5
        local half = (ring.outer - ring.inner) * 0.5 * depth
        local dInner = mid - half
        local dOuter = mid + half
        for _, seg in ipairs(ring.segs) do
            if seg.arcW >= 360 then
                drawArc(dInner, dOuter, 0, 360)
            else
                local as = segArcStart(slot, seg)
                drawArc(dInner, dOuter, as, seg.arcW)
            end
        end
    end

    -- Bridges on visible gaps
    for gap = ringStart, ringEnd do
        local bGM, bHL, bHW
        if gap < S.RING_COUNT then
            local ri = S.RINGS[gap]
            local ro = S.RINGS[gap + 1]
            bGM = (ri.inner + ro.outer) * 0.5
            bHL = (ri.inner - ro.outer) * 0.5 + 4
            local rawHW = math.min((ri.outer - ri.inner) * 0.5, (ro.outer - ro.inner) * 0.5)
            local innerFactor = 1.0 - (gap - ringStart) / math.max(1, ringEnd - ringStart) * 0.6
            bHW = rawHW * innerFactor
            if #ri.segs == 3 then bHW = bHW * 0.65 end
            if S.RINGS[gap+1] and #S.RINGS[gap+1].segs == 3 then bHW = bHW * 0.65 end
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
                    if bs.state ~= 'closed' then
                        local MIN_T = (4 + 5) / (2 * bHL)
                        local effT = math.max(bs.t, MIN_T)
                        local flicker = (bs.state == 'open' and bs.timer <= S.BRIDGE_WARN)
                            and (math.floor(nowMs / 80) % 3 == 0)
                        if not flicker then
                            local visLen = bHL * effT
                            local midShift = bHL * (1 - effT)
                            drawBridgeShape(ba, bGM + midShift, visLen, bHW)
                        end
                    end
                else
                    drawBridgeShape(ba, bGM, bHL, bHW)
                end
            end
        end

        -- up-bridges
        if gap < S.RING_COUNT then
            local innerRing = S.RINGS[gap+1]
            for si, seg in ipairs(innerRing.segs) do
                if seg.bOff_up and #seg.bOff_up > 0 then
                    local bas = segBridgeAnglesFrom(gap+1, seg, seg.bOff_up)
                    for bi, ba in ipairs(bas) do
                        local bs = S.bStates_up[gap+1] and S.bStates_up[gap+1][si] and S.bStates_up[gap+1][si][bi]
                        if bs then
                            if bs.state ~= 'closed' then
                                local MIN_T = (4 + 5) / (2 * bHL)
                                local effT = math.max(bs.t, MIN_T)
                                local flicker = (bs.state == 'open' and bs.timer <= S.BRIDGE_WARN)
                                    and (math.floor(nowMs / 80) % 3 == 0)
                                if not flicker then
                                    local visLen = bHL * effT
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

    -- Pulsating center
    local pulse = 1.0 + 0.06 * math.sin(nowMs / 1000 * math.pi * 2 * 1.2)
    local pulseR = math.max(2, sc(S.CENTER_R) * pulse)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(S.cx, S.cy, pulseR)
end

-- ---------------------------------------------------------------------------
function drawTrailParticles()
    local n = #S.playerHistory
    for i, h in ipairs(S.playerHistory) do
        local t = i / n
        local sz = math.max(1, math.floor(t * 6 + 0.5))
        local hf = math.floor(sz / 2)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(math.floor(h.x) - hf, math.floor(h.y) - hf, sz, sz)
    end
    for _, p in ipairs(S.particles) do
        local t = p.life / S.TRAIL_LIFE
        local sz = (t > 0.66) and 3 or (t > 0.33) and 2 or 1
        local hf = math.floor(sz / 2)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(math.floor(p.x) - hf, math.floor(p.y) - hf, sz, sz)
    end
end

-- ---------------------------------------------------------------------------
function drawPlayer()
    if (S.playerHitTimer or 0) > 0 and math.floor((S.playerHitTimer or 0) * 8) % 2 == 0 then return end
    local px, py
    if S.transiting then
        local toRing = math.max(1, math.min(S.RING_COUNT, S.playerRing + S.transDir))
        local r1 = sc(S.RINGS[S.playerRing].mid)
        local r2 = sc(S.RINGS[toRing].mid)
        local r = r1 + (r2 - r1) * S.transT
        local a = math.rad(S.transAngle)
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
    gfx.fillRect(ipx+1, ipy-2, 1, 1)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawLine(ipx-3, ipy-4, ipx-4, ipy-5)
    gfx.drawLine(ipx, ipy-5, ipx, ipy-6)
    gfx.drawLine(ipx+3, ipy-4, ipx+4, ipy-5)
end

-- ---------------------------------------------------------------------------
function drawEnemies()
    local n = #S.enemyParticles
    local dirs = {{1,1},{-1,1},{1,-1},{-1,-1},{1,0},{0,1}}
    for i, p in ipairs(S.enemyParticles) do
        local t = i / math.max(1, n)
        local ix = math.floor(p.x)
        local iy = math.floor(p.y)
        local dir = dirs[((i-1) % #dirs)+1]
        local ox = ((i*7) % 5) - 2
        local oy = ((i*13) % 5) - 2
        gfx.setColor(gfx.kColorBlack)
        if t > 0.65 then
            gfx.drawLine(ix+ox, iy+oy, ix+ox+dir[1]*3, iy+oy+dir[2]*3)
            local dir2 = dirs[((i+2) % #dirs)+1]
            gfx.drawLine(ix+ox, iy+oy, ix+ox+dir2[1]*2, iy+oy+dir2[2]*2)
        elseif t > 0.35 then
            gfx.drawLine(ix+ox, iy+oy, ix+ox+dir[1]*2, iy+oy+dir[2]*2)
        else
            gfx.fillRect(ix+ox, iy+oy, 1, 1)
        end
    end
    for _, p in ipairs(S.burstParticles) do
        local t = p.life / p.maxLife
        local sz = (t > 0.66) and 3 or (t > 0.33) and 2 or 1
        local hf = math.floor(sz / 2)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(math.floor(p.x)-hf, math.floor(p.y)-hf, sz, sz)
    end
    for _, e in ipairs(S.enemies) do
        local px, py, hl, hw, ang
        if e.spawning then
            local ring = S.RINGS[S.RING_COUNT]
            local a = math.rad(e.angle)
            local r = sc(ring.mid) * e.spawnT
            px = S.cx + r * math.sin(a)
            py = S.cy - r * math.cos(a)
            local depth = 1.0 - (S.RING_COUNT-1)/math.max(1, S.RING_COUNT-1)*0.55
            local half = (ring.outer - ring.inner) * depth * S.zoom * 0.5
            hl = half; hw = half; ang = e.angle
        elseif e.onGap then
            local gap = e.gapDir
            local ri = S.RINGS[gap]
            local ro = S.RINGS[gap+1]
            if not (ri and ro) then goto continueE end
            px, py = entityPosOnGap(gap, e.gapT, e.gapAngle)
            local rawHW = math.min((ri.outer-ri.inner)*0.5, (ro.outer-ro.inner)*0.5)
            hw = rawHW * S.zoom
            if #ri.segs == 3 then hw = hw * 0.65 end
            if #ro.segs == 3 then hw = hw * 0.65 end
            hl = hw; ang = e.gapAngle
        else
            px, py = entityPos(e.ring, e.angle)
            local ring = S.RINGS[e.ring or 1]
            local depth = 1.0 - ((e.ring or 1)-1)/math.max(1, S.RING_COUNT-1)*0.55
            local half = (ring.outer-ring.inner)*depth*S.zoom*0.5
            hl = half; hw = half; ang = e.angle
        end
        drawEnemyAtAngle(px, py, hl, hw, ang, e.type)
        ::continueE::
    end
end

-- ---------------------------------------------------------------------------
function drawImplode(t)
    local pullTE = t * t * (3 - 2 * t)
    local shakeAmp = math.sin(t * math.pi) * 14
    local shakeX = math.floor((math.random()*2-1)*shakeAmp)
    local shakeY = math.floor((math.random()*2-1)*shakeAmp)
    local savZoom = S.zoom
    S.zoom = S.implodeBaseZoom or S.zoom
    local savCx, savCy = S.cx, S.cy
    S.cx = 200 + shakeX
    S.cy = 120 + shakeY
    drawBoard()
    S.cx, S.cy = savCx, savCy
    S.zoom = savZoom

    if t < 0.7 then
        local dotT = t / 0.7
        local dotTE = dotT * dotT * (3 - 2 * dotT)
        local px = S.ppx + (200+shakeX - S.ppx) * dotTE
        local py = S.ppy + (120+shakeY - S.ppy) * dotTE
        local pr = math.max(1, math.floor(5 * (1-dotTE) + 0.5))
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(math.floor(px), math.floor(py), pr)
    end
    local holeR = math.floor(pullTE * pullTE * 230)
    if holeR > 0 then
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(200+shakeX, 120+shakeY, holeR)
    end
end

function drawHUD() end

function drawGameOver()
    drawScanlineBg()
    local tw, th = gfx.getTextSize("GAME OVER")
    local titleImg = gfx.image.new(tw+4, th+2)
    gfx.pushContext(titleImg)
    gfx.drawText("GAME OVER", 1, 1)
    gfx.drawText("GAME OVER", 2, 1)
    gfx.popContext()
    local tScale = 2.5
    local tImgW = (tw+4)*tScale
    titleImg:drawScaled(math.floor((400-tImgW)/2), 80, tScale)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 196, 400, 44)
    local aX, aY = 130, 218
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(aX, aY, 9)
    local aw, ah = gfx.getTextSize("A")
    local aTextX = aX - math.floor((aw+1)/2)
    local aTextY = aY - math.floor(ah/2)
    gfx.drawText("A", aTextX, aTextY)
    gfx.drawText("A", aTextX+1, aTextY)
    gfx.setImageDrawMode(gfx.kDrawModeInverted)
    gfx.drawText("RESTART", aX+13, aTextY)
    gfx.drawText("RESTART", aX+14, aTextY)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    local bX, bY = 258, 218
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(bX, bY, 9)
    local bw, bh = gfx.getTextSize("B")
    local bTextX = bX - math.floor((bw+1)/2)
    local bTextY = bY - math.floor(bh/2)
    gfx.drawText("B", bTextX, bTextY)
    gfx.drawText("B", bTextX+1, bTextY)
    gfx.setImageDrawMode(gfx.kDrawModeInverted)
    gfx.drawText("EXIT", bX+13, bTextY)
    gfx.drawText("EXIT", bX+14, bTextY)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function drawWin()
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, 400, 240)
    gfx.setImageDrawMode(gfx.kDrawModeInverted)
    gfx.drawText('YOU  WIN!', 160, 100)
    gfx.drawText('PRESS  A  TO  RETRY', 108, 170)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

-- Title screen
local TITLE_CX = 200
local TITLE_CY = 120
local TITLE_R = 90
local TITLE_THICK = 16

local function drawTitleBase()
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, 400, 240)
    local items = {"START GAME", "OPTIONS", "EXIT"}
    local itemH = 22
    local totalH = #items * itemH
    local startY = TITLE_CY - math.floor(totalH/2) + 2
    gfx.setColor(gfx.kColorWhite)
    for i, item in ipairs(items) do
        local iw, ih = gfx.getTextSize(item)
        local ix = math.floor((400-iw)/2)
        local iy = startY + (i-1)*itemH + math.floor((itemH-ih)/2)
        gfx.setImageDrawMode(gfx.kDrawModeInverted)
        gfx.drawText(item, ix, iy); gfx.drawText(item, ix+1, iy)
        gfx.drawText(item, ix, iy+1); gfx.drawText(item, ix+1, iy+1)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        if i == S.titleMenuIdx then
            local arrowX = ix - 10
            local arrowMY = iy + math.floor(ih/2)
            gfx.setColor(gfx.kColorWhite)
            gfx.fillPolygon(arrowX+6, arrowMY, arrowX, arrowMY-4, arrowX, arrowMY+4)
        end
    end
end

function drawTitleScreen()
    drawTitleBase()
    if S.titleCircleT > 0 then
        local sweep = math.min(1.0, S.titleCircleT) * 360
        local steps = math.max(3, math.ceil(sweep/3))
        local da = sweep / steps
        local r1 = TITLE_R - TITLE_THICK
        local r2 = TITLE_R
        gfx.setColor(gfx.kColorWhite)
        for i = 0, steps-1 do
            local a1 = math.rad(-90 + i*da)
            local a2 = math.rad(-90 + (i+1)*da)
            gfx.fillPolygon(
                math.floor(TITLE_CX + r2*math.cos(a1)), math.floor(TITLE_CY + r2*math.sin(a1)),
                math.floor(TITLE_CX + r2*math.cos(a2)), math.floor(TITLE_CY + r2*math.sin(a2)),
                math.floor(TITLE_CX + r1*math.cos(a2)), math.floor(TITLE_CY + r1*math.sin(a2)),
                math.floor(TITLE_CX + r1*math.cos(a1)), math.floor(TITLE_CY + r1*math.sin(a1))
            )
        end
    end
end

function drawTitleFill(t)
    local tE = t * t * (3 - 2 * t)
    drawTitleBase()
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(TITLE_CX, TITLE_CY, TITLE_R)
    local innerR = math.floor((TITLE_R - TITLE_THICK) * (1 - tE))
    if innerR > 0 then
        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(TITLE_CX, TITLE_CY, innerR)
    end
end

function drawTitleZoomOut(t)
    local tE = t * t * (3 - 2 * t)
    local startZoom = TITLE_R / S.CENTER_R
    local endZoom = 115 / S.RINGS[math.min(8, S.RING_COUNT)].outer
    local savCx, savCy, savZoom = S.cx, S.cy, S.zoom
    S.cx = 200; S.cy = 120
    S.zoom = startZoom + (endZoom - startZoom) * tE
    drawBoard()
    S.cx, S.cy, S.zoom = savCx, savCy, savZoom
end
"@

# ============================================================================
# main.lua - simplified game loop
# ============================================================================
wf "main.lua" @"
import "CoreLibs/graphics"
import "gfxp"
import "sfx"
import "music"
local gfxp <const> = GFXP
import "model"
import "view"
import "controller"

local gfx  <const> = playdate.graphics
local math <const> = math

resetGame()
S.gameState = S.STATE_TITLE

S.lastMs = playdate.getCurrentTimeMilliseconds()

local sysMenu = playdate.getSystemMenu()
sysMenu:addMenuItem("Hauptmenu", function()
    S.gameState    = S.STATE_TITLE
    S.titleAnim    = 'idle'
    S.titleAnimT   = 0.0
    S.titleCircleT = 0.0
end)
sysMenu:addMenuItem("Neu starten", function()
    setupLevel()
    S.gameState      = S.STATE_PLAY
    S.deadTimer      = 0.0
    S.playerHitTimer = 0.0
end)

function playdate.gameWillTerminate()
    playdate.datastore.write({}, "save")
end

function playdate.update()
    local now = playdate.getCurrentTimeMilliseconds()
    local dt  = math.min((now - S.lastMs) / 1000.0, 0.05)
    S.lastMs  = now

    if S.gameState == S.STATE_TITLE then
        if S.titleAnim == 'idle' then
            S.titleCircleT = math.min(S.titleCircleT + dt / S.TITLE_CIRCLE_DUR, 1.0)
            if playdate.buttonJustPressed(playdate.kButtonUp) then
                S.titleMenuIdx = ((S.titleMenuIdx - 2) % 3) + 1
            end
            if playdate.buttonJustPressed(playdate.kButtonDown) then
                S.titleMenuIdx = (S.titleMenuIdx % 3) + 1
            end
            if playdate.buttonJustPressed(playdate.kButtonA) then
                if S.titleMenuIdx == 1 then
                    resetGame()
                    S.gameState  = S.STATE_TITLE
                    S.titleAnim  = 'fill'
                    S.titleAnimT = 0.0
                end
            end
            drawTitleScreen()
        elseif S.titleAnim == 'fill' then
            S.titleAnimT = math.min(S.titleAnimT + dt / S.TITLE_FILL_DUR, 1.0)
            drawTitleFill(S.titleAnimT)
            if S.titleAnimT >= 1.0 then
                S.titleAnim  = 'zoom'
                S.titleAnimT = 0.0
            end
        elseif S.titleAnim == 'zoom' then
            S.titleAnimT = math.min(S.titleAnimT + dt / S.TITLE_ZOOM_DUR, 1.0)
            drawTitleZoomOut(S.titleAnimT)
            if S.titleAnimT >= 1.0 then
                S.titleAnim  = 'idle'
                S.titleAnimT = 0.0
                S.gameState  = S.STATE_PLAY
            end
        end
        return
    end

    if S.gameState == S.STATE_IMPLODE then
        S.implodeT = S.implodeT + dt / S.IMPLODE_DUR
        if S.implodeT >= 1.0 then
            S.gameState = S.STATE_WIN
            S.implodeT = 0.0
        else
            drawImplode(S.implodeT)
        end
        return
    end

    if S.gameState == S.STATE_DEAD then
        S.deadTimer = S.deadTimer + dt
        for i = #S.shatterPieces, 1, -1 do
            local p = S.shatterPieces[i]
            p.x    = p.x + p.vx * dt
            p.y    = p.y + p.vy * dt
            p.vy   = p.vy + 100 * dt
            p.life = p.life - dt
            if p.life <= 0 then table.remove(S.shatterPieces, i) end
        end
        if math.floor(S.deadTimer * 6) % 2 == 0 then
            drawBoard()
            drawEnemies()
            drawHUD()
            for _, p in ipairs(S.shatterPieces) do
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
        if S.deadTimer >= S.DEAD_HOLD then
            respawnPlayer()
        end
        return
    end

    if S.gameState == S.STATE_WIN then
        drawWin()
        if playdate.buttonJustPressed(playdate.kButtonA) then
            resetGame()
        end
        return
    end

    updateBridges(dt)
    updatePlayer(dt)
    if S.gameState ~= S.STATE_PLAY then return end
    updateEnemies(dt)
    updateEnemyTrails(dt)
    updateCollision()

    drawBoard()
    drawTrailParticles()
    drawEnemies()
    drawPlayer()

    if (S.hitFlashTimer or 0) > 0 then
        S.hitFlashTimer = S.hitFlashTimer - dt
        if math.floor(S.hitFlashTimer * 12) % 2 == 0 then
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(0, 0, 400, 240)
        end
    end

    drawHUD()
end
"@

Write-Host "All files written without BOM"
