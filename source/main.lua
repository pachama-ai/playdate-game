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

-- (All state, constants, draw and update functions are now in model/view/controller)

resetGame()
S.gameState = S.STATE_TITLE

-- Gespeicherten Spielstand laden (kein Auto-Start: Neustart immer bei Level 1)
local _save = playdate.datastore.read("save")
-- _save.level ist verfuegbar aber wird nicht automatisch angewendet

S.lastMs = playdate.getCurrentTimeMilliseconds()

-- Playdate-Systemmenü: zwei eigene Eintraege
local sysMenu = playdate.getSystemMenu()
sysMenu:addMenuItem("Hauptmenu", function()
    S.gameState    = S.STATE_TITLE
    S.titleAnim    = 'idle'
    S.titleAnimT   = 0.0
    S.titleCircleT = 0.0
end)
sysMenu:addMenuItem("Neu starten", function()
    setupLevel(S.level)
    S.gameState      = S.STATE_PLAY
    S.deadTimer      = 0.0
    S.playerHitTimer = 0.0
end)

function playdate.gameWillTerminate()
    playdate.datastore.write({level = S.level}, "save")
end

function playdate.update()
    local now = playdate.getCurrentTimeMilliseconds()
    local dt  = math.min((now - S.lastMs) / 1000.0, 0.05)
    S.lastMs  = now

    if S.gameState == S.STATE_TITLE then
        if S.titleAnim == 'idle' then
            S.titleCircleT = math.min(S.titleCircleT + dt / S.TITLE_CIRCLE_DUR, 1.0)
            -- Kurbel: Level auswaehlen (40°-Schritte)
            S.titleCrankAcc = (S.titleCrankAcc or 0) + playdate.getCrankChange()
            if S.titleCrankAcc >= 40 then
                S.titleCrankAcc = S.titleCrankAcc - 40
                S.selectedLevel = math.min(S.MAX_LEVEL, (S.selectedLevel or 1) + 1)
            elseif S.titleCrankAcc <= -40 then
                S.titleCrankAcc = S.titleCrankAcc + 40
                S.selectedLevel = math.max(1, (S.selectedLevel or 1) - 1)
            end
            if playdate.buttonJustPressed(playdate.kButtonUp) then
                S.titleMenuIdx = ((S.titleMenuIdx - 2) % 3) + 1
            end
            if playdate.buttonJustPressed(playdate.kButtonDown) then
                S.titleMenuIdx = (S.titleMenuIdx % 3) + 1
            end
            if playdate.buttonJustPressed(playdate.kButtonA) then
                if S.titleMenuIdx == 1 then
                    resetGame()
                    if (S.selectedLevel or 1) > 1 then
                        S.level = S.selectedLevel
                        setupLevel(S.level)
                    end
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
            S.level = S.level + 1
            if S.level > S.MAX_LEVEL then
                S.gameState = S.STATE_WIN
            else
                setupLevel(S.level)
                playdate.datastore.write({level = S.level}, "save")
                S.gameState = S.STATE_PLAY
            end
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
            respawnPlayer()  -- kein Game Over, immer respawnen
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
    updateMusic(dt, S.playerRing, S.RING_COUNT)
    updatePlayer(dt)
    if S.gameState ~= S.STATE_PLAY then return end
    --updateEnemies(dt)
    --updateEnemyTrails(dt)
    --updateCollision()

    drawBoard()
    drawHUD()
    drawTrailParticles()
    --drawEnemies()
    drawPlayer()

    -- Hit-Flash: 3x schwarz aufblitzen bei Treffer
    if (S.hitFlashTimer or 0) > 0 then
        S.hitFlashTimer = S.hitFlashTimer - dt
        if math.floor(S.hitFlashTimer * 12) % 2 == 0 then
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(0, 0, 400, 240)
        end
    end

    drawHUD()
end

-- (legacy code replaced by modules below Ã¢â‚¬â€ kept as empty stub)
