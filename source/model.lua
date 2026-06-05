-- model.lua: global state table S + shared helper functions
-- NEW ARCHITECTURE: each slot contains a list of independent arc-segments.
-- A segment { arcW, startOff, bOff, closeable }
-- arcW      : arc width in degrees (360 = full circle)
-- startOff  : angular offset of segment centre from slot driver (degrees)
-- bOff      : list of bridge offsets from arc-start in degrees
-- closeable : list of bool per bridge (true = uses open/close cycle)

local math <const> = math

S = {}

-- Screen centre
S.cx = 200
S.cy = 120

-- ---------------------------------------------------------------------------
-- Level-spezifische Ring-Queues (je 8 Slots, outer -> inner)
--   L1 = leicht:  langsam, alle Brücken statisch, weite Bögen
--   L2 = mittel:  original-Design
--   L3 = schwer:  schnell, enge Bögen, viele schließbare Brücken
-- ---------------------------------------------------------------------------

-- Level 1 – Einstieg: Original-Brücken/-Segmente, nur langsamere Rotation
S.RING_QUEUE_L1 = {
    -- 1: Vollkreis, langsam CW (original: 18)
    {
        rot  = { dir=1, speed=11, pauseLen=0.4, startAngle=0 },
        segs = {
            { arcW=360, startOff=0, bOff={}, closeable={}, bOff_up={}, closeable_up={} },
        },
    },
    -- 2: 6 × 50°, CCW swing, 3 closeable + 3 Sackgassen
    {
        rot  = { dir=-1, speed=16, pauseLen=1.0, startAngle=15,
                 swingPts={15, 90, 45, 135} },
        segs = {
            { arcW=50, startOff=  0, bOff={18}, closeable={true},  bOff_up={33}, closeable_up={false} },
            { arcW=50, startOff= 60, bOff={},   closeable={},      bOff_up={21}, closeable_up={false} },
            { arcW=50, startOff=120, bOff={},   closeable={},      bOff_up={35}, closeable_up={false} },
            { arcW=50, startOff=180, bOff={11}, closeable={true},  bOff_up={17}, closeable_up={false} },
            { arcW=50, startOff=240, bOff={},   closeable={},      bOff_up={29}, closeable_up={false} },
            { arcW=50, startOff=300, bOff={36}, closeable={true},  bOff_up={37}, closeable_up={false} },
        },
    },
    -- 3: Vollkreis, mittellangsam CW (original: 22)
    {
        rot  = { dir=1, speed=14, pauseLen=0.6, startAngle=60 },
        segs = {
            { arcW=360, startOff=0, bOff={}, closeable={}, bOff_up={}, closeable_up={} },
        },
    },
    -- 4: 2 × 120°, CW, 1 Sackgasse, 1 closeable
    {
        rot  = { dir=1, speed=22, pauseLen=0.8, startAngle=30,
                 swingPts={30, 100, 60} },
        segs = {
            { arcW=120, startOff=  0, bOff={35}, closeable={true},  bOff_up={88}, closeable_up={false} },
            { arcW=120, startOff=150, bOff={},   closeable={},      bOff_up={45}, closeable_up={false} },
        },
    },
    -- 5: Vollkreis, keine Bruecken
    {
        rot  = { dir=1, speed=7, pauseLen=1.5, startAngle=0 },
        segs = {
            { arcW=360, startOff=0, bOff={}, closeable={}, bOff_up={}, closeable_up={} },
        },
    },
    -- 6: 4 Segmente, CCW swing – 2 Brücken, 2 Sackgassen
    {
        rot  = { dir=-1, speed=30, pauseLen=0.4, startAngle=20,
                 swingPts={20, 90, 50, 130} },
        segs = {
            { arcW=65, startOff=  0, bOff={22}, closeable={true},  bOff_up={38}, closeable_up={false} },
            { arcW=45, startOff=110, bOff={},   closeable={},      bOff_up={22}, closeable_up={false} },
            { arcW=65, startOff=200, bOff={48}, closeable={true},  bOff_up={30}, closeable_up={false} },
            { arcW=50, startOff=300, bOff={},   closeable={},      bOff_up={40}, closeable_up={false} },
        },
    },
    -- 7: Vollkreis, schneller CW
    {
        rot  = { dir=1, speed=36, pauseLen=0.25, startAngle=0 },
        segs = {
            { arcW=360, startOff=0, bOff={}, closeable={}, bOff_up={}, closeable_up={} },
        },
    },
    -- 8: 5 × 60°, CW swing – 2 closeable, 2 Sackgassen
    {
        rot  = { dir=1, speed=26, pauseLen=0.6, startAngle=10,
                 swingPts={10, 75, 40, 110, 55} },
        segs = {
            { arcW=60, startOff=  0, bOff={22}, closeable={true},  bOff_up={44}, closeable_up={false} },
            { arcW=60, startOff= 72, bOff={},   closeable={},      bOff_up={31}, closeable_up={false} },
            { arcW=60, startOff=144, bOff={},   closeable={},      bOff_up={22}, closeable_up={false} },
            { arcW=60, startOff=216, bOff={30}, closeable={true},  bOff_up={46}, closeable_up={false} },
            { arcW=60, startOff=288, bOff={35}, closeable={false}, bOff_up={28}, closeable_up={false} },
        },
    },
}

-- Level 2 – Mittel: schnellere Drehungen, mehr Sackgassen, mehr Gegner
S.RING_QUEUE_L2 = {
    -- 1: Vollkreis, schnell CW
    {
        rot  = { dir=1, speed=28, pauseLen=0.25, startAngle=0 },
        segs = {
            { arcW=360, startOff=0, bOff={}, closeable={}, bOff_up={}, closeable_up={} },
        },
    },
    -- 2: 4×75°, CCW swing, 1 closeable + 2 Sackgassen
    {
        rot  = { dir=-1, speed=32, pauseLen=0.55, startAngle=20,
                 swingPts={20, 200, 110, 290} },
        segs = {
            { arcW=75, startOff=  0, bOff={38}, closeable={true},  bOff_up={55}, closeable_up={false} },
            { arcW=75, startOff= 90, bOff={},   closeable={},      bOff_up={40}, closeable_up={false} },
            { arcW=75, startOff=180, bOff={55}, closeable={false}, bOff_up={25}, closeable_up={false} },
            { arcW=75, startOff=270, bOff={},   closeable={},      bOff_up={60}, closeable_up={false} },
        },
    },
    -- 3: Vollkreis, schnell CCW
    {
        rot  = { dir=-1, speed=25, pauseLen=0.4, startAngle=45 },
        segs = {
            { arcW=360, startOff=0, bOff={}, closeable={}, bOff_up={}, closeable_up={} },
        },
    },
    -- 4: 3×105°, CW, 1 closeable + 2 Sackgassen
    {
        rot  = { dir=1, speed=38, pauseLen=0.4, startAngle=15,
                 swingPts={15, 185, 100, 270} },
        segs = {
            { arcW=105, startOff=  0, bOff={},   closeable={},      bOff_up={88}, closeable_up={false} },
            { arcW=105, startOff=120, bOff={55}, closeable={true},  bOff_up={40}, closeable_up={false} },
            { arcW=105, startOff=240, bOff={},   closeable={},      bOff_up={75}, closeable_up={false} },
        },
    },
    -- 5: Vollkreis, mittelschnell CCW
    {
        rot  = { dir=-1, speed=16, pauseLen=0.85, startAngle=0 },
        segs = {
            { arcW=360, startOff=0, bOff={}, closeable={}, bOff_up={}, closeable_up={} },
        },
    },
    -- 6: 5×52°, CCW swing, 2 closeable + 3 Sackgassen
    {
        rot  = { dir=-1, speed=44, pauseLen=0.18, startAngle=10,
                 swingPts={10, 185, 95, 270, 150} },
        segs = {
            { arcW=52, startOff=  0, bOff={25}, closeable={true},  bOff_up={38}, closeable_up={false} },
            { arcW=52, startOff= 72, bOff={},   closeable={},      bOff_up={20}, closeable_up={false} },
            { arcW=52, startOff=144, bOff={},   closeable={},      bOff_up={42}, closeable_up={false} },
            { arcW=52, startOff=216, bOff={30}, closeable={true},  bOff_up={15}, closeable_up={false} },
            { arcW=52, startOff=288, bOff={},   closeable={},      bOff_up={35}, closeable_up={false} },
        },
    },
    -- 7: Vollkreis, sehr schnell CW
    {
        rot  = { dir=1, speed=38, pauseLen=0.18, startAngle=0 },
        segs = {
            { arcW=360, startOff=0, bOff={}, closeable={}, bOff_up={}, closeable_up={} },
        },
    },
    -- 8: 4×65°, CW swing, 1 closeable + 3 Sackgassen
    {
        rot  = { dir=1, speed=40, pauseLen=0.3, startAngle=5,
                 swingPts={5, 185, 95, 275} },
        segs = {
            { arcW=65, startOff=  0, bOff={},   closeable={},     bOff_up={50}, closeable_up={false} },
            { arcW=65, startOff= 90, bOff={32}, closeable={true}, bOff_up={32}, closeable_up={false} },
            { arcW=65, startOff=180, bOff={},   closeable={},     bOff_up={55}, closeable_up={false} },
            { arcW=65, startOff=270, bOff={},   closeable={},     bOff_up={40}, closeable_up={false} },
        },
    },
}

-- Level 3 – Schwer: schnelle Ringe, enge Bögen, viele schließbare Brücken, Fallen
S.RING_QUEUE_L3 = {
    -- 1: Vollkreis, sehr schnell CW
    {
        rot  = { dir=1, speed=30, pauseLen=0.2, startAngle=0 },
        segs = {
            { arcW=360, startOff=0, bOff={}, closeable={}, bOff_up={}, closeable_up={} },
        },
    },
    -- 2: 6 × 45°, schnell CW, 4 closeable + 3 Sackgassen
    {
        rot  = { dir=1, speed=38, pauseLen=0.4, startAngle=20,
                 swingPts={20, 200, 100, 280} },
        segs = {
            { arcW=45, startOff=  0, bOff={20}, closeable={true},  bOff_up={30}, closeable_up={false} },
            { arcW=45, startOff= 60, bOff={},   closeable={},      bOff_up={15}, closeable_up={false} },
            { arcW=45, startOff=120, bOff={},   closeable={},      bOff_up={35}, closeable_up={false} },
            { arcW=45, startOff=180, bOff={20}, closeable={true},  bOff_up={28}, closeable_up={false} },
            { arcW=45, startOff=240, bOff={22}, closeable={true},  bOff_up={40}, closeable_up={false} },
            { arcW=45, startOff=300, bOff={},   closeable={},      bOff_up={22}, closeable_up={false} },
        },
    },
    -- 3: Vollkreis, sehr schnell CCW
    {
        rot  = { dir=-1, speed=35, pauseLen=0.15, startAngle=90 },
        segs = {
            { arcW=360, startOff=0, bOff={}, closeable={}, bOff_up={}, closeable_up={} },
        },
    },
    -- 4: 4 × 60°, sehr schnell swing CW, 3 closeable (1 Falle)
    {
        rot  = { dir=1, speed=42, pauseLen=0.25, startAngle=10,
                 swingPts={10, 190, 70, 250} },
        segs = {
            { arcW=60, startOff=  0, bOff={15,45}, closeable={true,true}, bOff_up={40}, closeable_up={false} },
            { arcW=60, startOff= 90, bOff={30},    closeable={true},      bOff_up={50}, closeable_up={false} },
            { arcW=60, startOff=180, bOff={},      closeable={},          bOff_up={20}, closeable_up={false} },
            { arcW=60, startOff=270, bOff={30},    closeable={true},      bOff_up={45}, closeable_up={false} },
        },
    },
    -- 5: Vollkreis, mittelschnell CW
    {
        rot  = { dir=1, speed=18, pauseLen=0.8, startAngle=0 },
        segs = {
            { arcW=360, startOff=0, bOff={}, closeable={}, bOff_up={}, closeable_up={} },
        },
    },
    -- 6: 4 × 50°, extrem schnell swing CCW, alle closeable (1 Falle)
    {
        rot  = { dir=-1, speed=52, pauseLen=0.15, startAngle=15,
                 swingPts={15, 200, 80, 260} },
        segs = {
            { arcW=50, startOff=  0, bOff={15,35}, closeable={true,true}, bOff_up={30}, closeable_up={false} },
            { arcW=50, startOff= 90, bOff={25},    closeable={true},      bOff_up={40}, closeable_up={false} },
            { arcW=50, startOff=180, bOff={},      closeable={},          bOff_up={15}, closeable_up={false} },
            { arcW=50, startOff=270, bOff={25},    closeable={true},      bOff_up={35}, closeable_up={false} },
        },
    },
    -- 7: Vollkreis, sehr schnell CCW
    {
        rot  = { dir=-1, speed=40, pauseLen=0.15, startAngle=0 },
        segs = {
            { arcW=360, startOff=0, bOff={}, closeable={}, bOff_up={}, closeable_up={} },
        },
    },
    -- 8: 5 × 45°, sehr schnell swing CW, 3 closeable + 2 Sackgassen
    {
        rot  = { dir=1, speed=46, pauseLen=0.3, startAngle=5,
                 swingPts={5, 200, 85, 290, 150} },
        segs = {
            { arcW=45, startOff=  0, bOff={20}, closeable={true},  bOff_up={30}, closeable_up={false} },
            { arcW=45, startOff= 72, bOff={22}, closeable={true},  bOff_up={40}, closeable_up={false} },
            { arcW=45, startOff=144, bOff={20}, closeable={true},  bOff_up={28}, closeable_up={false} },
            { arcW=45, startOff=216, bOff={},   closeable={},      bOff_up={35}, closeable_up={false} },
            { arcW=45, startOff=288, bOff={},   closeable={},      bOff_up={30}, closeable_up={false} },
        },
    },
}

S.RING_QUEUE_ALL = S.RING_QUEUE_L2   -- default; wird in setupLevel() gesetzt
S.TOTAL_RINGS    = #S.RING_QUEUE_ALL

S.VISIBLE      = 5   -- max sichtbare Ringe
S.queueHead    = 1

-- Fixed radii for up to 5 visible slots (slot 1 = outermost, slot 5 = innermost)
-- Constraint: SLOT_OUTER[1] * ZOOM_TABLE[1] <= 120  →  88 * 1.3 = 114.4 ✓
-- Inner slots (3-5) are narrower so seg 6 looks less bulky near the centre.
S.SLOT_MID   = { 83, 65, 48, 32, 17 }
S.SLOT_INNER = { 78, 60, 44, 29, 14 }
S.SLOT_OUTER = { 88, 70, 52, 35, 20 }

-- S.RINGS[slot] = { mid, inner, outer, rot, segs, _rotState }
S.RINGS      = {}
S.RING_COUNT = 4   -- startet mit 4, waechst nach erstem Transit auf 5
S.CENTER_R   = 10

-- Bridge constants (seconds)
S.BRIDGE_OPEN_DUR   = 2.5
S.BRIDGE_CLOSE_T    = 0.4
S.BRIDGE_CLOSED_DUR = 4.0   -- 8 Sekunden geschlossen
S.BRIDGE_OPEN_T     = 0.4
S.BRIDGE_WARN       = 0.5
S.BRIDGE_HALF       = 14
S.BRIDGE_HALF_BACK  = 22

-- Scroll / zoom-sog state
S.scrolling       = false
S.scrollT         = 0.0
S.SCROLL_DUR      = 0.55
S.scrollZoomStart = 1.3   -- Zoom zu Beginn des Scrolls
S.scrollZoomMult  = 1.0   -- Multiplikator fuer Scroll-Ziel

-- Zoom (startet bei 1.3 = nah rangezoomt, geht bis 2.0 innen)
S.zoom       = 1.3
S.zoomTarget = 1.3
S.ZOOM_TABLE = {}
for i = 1, S.VISIBLE do
    S.ZOOM_TABLE[i] = 1.3 + (i - 1) / (S.VISIBLE - 1) * 0.7
end
-- Zoom geht nur leicht rein damit man zurueck kann ohne sich zu verlaufen

S.ringsCleared  = 0   -- wie viele Uebergaenge nach innen bereits gemacht
S.queueAdvances = 0   -- wie oft advanceQueue() bisher aufgerufen wurde
S.finalStage    = false  -- true nach dem letzten Queue-Vorschub: Spieler navigiert frei bis Ring 5

-- Per-slot driver angles and deltas
S.angles     = {}
S.ringDeltas = {}

-- Bridge states: S.bStates[slot][segIdx][bridgeIdx] = {state,timer,t} or nil
S.bStates    = {}
-- Up-bridge states (inner-ring bridges that face outward toward parent slot)
S.bStates_up = {}

-- Player
S.playerRing  = 1
S.playerSeg   = 1
S.playerAngle = 0.0
S.transiting  = false
S.transDir    = 0
S.transT      = 0.0
S.transAngle  = 0.0
S.TRANS_TIME  = 0.2
S.ppx         = 0
S.ppy         = 0

-- Enemies
S.enemies           = {}
S.ENEMY_SPEED       = 48
S.ENEMY_SPEED_MIN   = 24      -- untere Grenze Gegnertempo (pro Level gesetzt)
S.ENEMY_SPEED_MAX   = 72      -- obere Grenze Gegnertempo (pro Level gesetzt)
S.ENEMY_MAX         = 4       -- max. Gegner gleichzeitig (pro Level gesetzt)
S.ENEMY_GAP_SPD     = 1.5
S.spawnTimer        = 1.5
S.SPAWN_INTERVAL    = 3.5
S.ESCAPE_TIME       = 0.45
S.enemyFreezeTimer  = 0   -- Einfrierzeit nach Respawn

-- Input buffers
S.aBufTimer = 0.0
S.bBufTimer = 0.0
S.BUF_TIME  = 0.3

-- Game state
S.STATE_PLAY     = 'play'
S.STATE_DEAD     = 'dead'
S.STATE_IMPLODE  = 'implode'
S.STATE_GAMEOVER = 'gameover'
S.STATE_WIN      = 'win'
S.STATE_TITLE    = 'title'
S.MAX_LEVEL      = 3
S.titleMenuIdx   = 1
S.selectedLevel  = 1
S.titleCrankAcc  = 0.0
S.titleAnim      = 'idle'  -- 'idle' | 'slide' | 'zoom'
S.titleAnimT     = 0.0
S.titleCircleT   = 0.0
S.TITLE_CIRCLE_DUR = 1.2
S.TITLE_SLIDE_DUR = 0.55
S.TITLE_FILL_DUR  = 0.5
S.TITLE_ZOOM_DUR  = 0.65
S.gameState  = 'play'
S.deadTimer      = 0.0
S.DEAD_HOLD      = 2.0
S.playerHitTimer = 0.0
S.HIT_INVINCIBLE = 1.5
S.hitFlashTimer  = 0.0
S.implodeT       = 0.0
S.IMPLODE_DUR    = 1.8
S.level      = 1
S.lives      = 3
S.maxLives   = 3

-- Particles / trail
S.particles     = {}
S.TRAIL_LIFE    = 0.25
S.playerHistory = {}
S.HISTORY_MAX   = 4
S.shatterPieces  = {}
S.enemyParticles = {}
S.burstParticles = {}
S.enemyRotation  = 0

-- Frame timing
S.lastMs = 0

-- ---------------------------------------------------------------------------
-- Shared helper functions
-- ---------------------------------------------------------------------------

function sc(r) return r * S.zoom end

function angleDist(a, b)
    return math.abs(((a - b + 180) % 360) - 180)
end

-- World-angle of a segment's arc-start: driver + startOff - arcW/2
function segArcStart(slotIdx, seg)
    local driver = S.angles[slotIdx]
    return (driver + seg.startOff - seg.arcW * 0.5) % 360
end

-- Is worldAngle inside seg's arc on slotIdx?
function angleInSeg(slotIdx, seg, worldAngle)
    if seg.arcW >= 360 then return true end
    local as = segArcStart(slotIdx, seg)
    return ((worldAngle - as) % 360) < seg.arcW
end

-- Clamp worldAngle to nearest valid position on seg.
function clampToSeg(slotIdx, seg, worldAngle)
    if seg.arcW >= 360 then return worldAngle % 360 end
    local as = segArcStart(slotIdx, seg)
    local ae = (as + seg.arcW) % 360
    if ((worldAngle - as) % 360) <= seg.arcW then return worldAngle % 360 end
    if angleDist(worldAngle, as) <= angleDist(worldAngle, ae) then return as else return ae end
end

-- World-angles for an arbitrary bOff list on a segment.
function segBridgeAnglesFrom(slotIdx, seg, bOffList)
    local as  = segArcStart(slotIdx, seg)
    local out = {}
    for _, off in ipairs(bOffList) do
        table.insert(out, (as + off) % 360)
    end
    return out
end

-- World-angles of all inward bridges on a segment.
function segBridgeAngles(slotIdx, seg)
    return segBridgeAnglesFrom(slotIdx, seg, seg.bOff)
end

-- Collect all bridge entries on gap gapIdx.
-- Outer-ring bridges (seg.bOff) + inner-ring up-bridges (seg.bOff_up).
-- Returns list of {angle, slot, seg, bridge, open, state}
function getBridgesOnGap(gapIdx)
    local ring   = S.RINGS[gapIdx]
    local result = {}
    -- Bridges defined on the outer ring – driven by OWN ring (gapIdx), never floats.
    local innerDriver = (gapIdx < S.RING_COUNT) and (gapIdx + 1) or gapIdx
    for si, seg in ipairs(ring.segs) do
        local bas = segBridgeAnglesFrom(gapIdx, seg, seg.bOff)
        for bi, ba in ipairs(bas) do
            local bs     = S.bStates[gapIdx] and S.bStates[gapIdx][si] and S.bStates[gapIdx][si][bi]
            local isOpen = (not bs) or (bs.state == 'open') or (bs.state == 'opening')
            table.insert(result, { angle=ba, slot=gapIdx, seg=si, bridge=bi, open=isOpen, state=bs })
        end
    end
    -- Up-bridges on inner ring – driven by inner ring (gapIdx+1), never floats.
    if gapIdx < S.RING_COUNT then
        local innerRing = S.RINGS[gapIdx + 1]
        for si, seg in ipairs(innerRing.segs) do
            if seg.bOff_up and #seg.bOff_up > 0 then
                local bas = segBridgeAnglesFrom(gapIdx + 1, seg, seg.bOff_up)
                for bi, ba in ipairs(bas) do
                    local bs     = S.bStates_up[gapIdx+1] and S.bStates_up[gapIdx+1][si] and S.bStates_up[gapIdx+1][si][bi]
                    local isOpen = (not bs) or (bs.state == 'open') or (bs.state == 'opening')
                    table.insert(result, { angle=ba, slot=gapIdx+1, seg=si, bridge=bi, open=isOpen, state=bs })
                end
            end
        end
    end
    return result
end

-- Find nearest open bridge on gapIdx within tol degrees.
function nearBridge(gapIdx, angleDeg, tol)
    tol = tol or S.BRIDGE_HALF
    local bridges  = getBridgesOnGap(gapIdx)
    local bestDist = 999
    local bestAngle, bestSeg, bestBridge = nil, nil, nil
    for _, b in ipairs(bridges) do
        if b.open then
            local d = angleDist(angleDeg, b.angle)
            if d <= tol and d < bestDist then
                bestDist = d; bestAngle = b.angle; bestSeg = b.seg; bestBridge = b.bridge
            end
        end
    end
    if bestAngle then return true, bestAngle, bestSeg, bestBridge end
    return false, nil, nil, nil
end

-- Find which seg on slotIdx contains worldAngle (returns segIdx).
-- Falls back to nearest segment edge instead of defaulting to 1.
function findSeg(slotIdx, worldAngle)
    local ring = S.RINGS[slotIdx]
    for si, seg in ipairs(ring.segs) do
        if angleInSeg(slotIdx, seg, worldAngle) then return si end
    end
    -- Not in any segment: return nearest by arc endpoints
    local bestSi, bestDist = 1, 361
    for si, seg in ipairs(ring.segs) do
        local as = segArcStart(slotIdx, seg)
        local ae = (as + seg.arcW) % 360
        local d  = math.min(angleDist(worldAngle, as), angleDist(worldAngle, ae))
        if d < bestDist then bestDist = d; bestSi = si end
    end
    return bestSi
end

function entityPos(ring, angle)
    local r   = sc(S.RINGS[ring].mid)
    local rad = math.rad(angle)
    return S.cx + r * math.sin(rad), S.cy - r * math.cos(rad)
end

function entityPosOnGap(gapIdx, t, angle)
    local r1  = sc(S.RINGS[gapIdx].mid)
    local r2  = sc(S.RINGS[gapIdx + 1].mid)
    local r   = r1 + (r2 - r1) * t
    local rad = math.rad(angle)
    return S.cx + r * math.sin(rad), S.cy - r * math.cos(rad)
end
