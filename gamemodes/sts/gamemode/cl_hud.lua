include("descriptions.lua")
include("teamsetup.lua")
AddCSLuaFile("descriptions.lua")
local REF_W, REF_H = 1920, 1080
local function ScaleW(x)
    return x * (ScrW() / REF_W)
end

local function ScaleH(y)
    return y * (ScrH() / REF_H)
end

function HUD()
    local client = LocalPlayer()
    if not client:Alive() then return end
    local tickCount = engine.TickCount()
    local screenWidth = ScrW()
    local screenHeight = ScrH()
    local cornerRadiusSmall = math.min(ScaleW(5), ScaleH(5))
    local cornerRadiusLarge = math.min(ScaleW(25), ScaleH(25))
    local descriptionsEnabled = GetConVar("sts_use_descriptions"):GetInt()
    ----------------------------------------------------------------
    -- Health
    ----------------------------------------------------------------
    draw.RoundedBox(cornerRadiusSmall, 0, screenHeight - ScaleH(140), ScaleW(250), ScaleH(240), Color(20, 20, 20, 225))
    -- Health text
    draw.SimpleText("Health: " .. client:Health() .. "%", "DermaDefaultBold", ScaleW(10), screenHeight - ScaleH(65), Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    -- Health bar background
    draw.RoundedBox(3, ScaleW(10), screenHeight - ScaleH(50), ScaleW(225), ScaleH(15), Color(250, 0, 0, 30))
    -- Health bar foreground
    draw.RoundedBox(3, ScaleW(10), screenHeight - ScaleH(50), math.Clamp(client:Health(), 0, 100) * ScaleW(2.25), ScaleH(15), Color(255, 0, 0, 255))
    -- Extra highlight strip
    draw.RoundedBox(3, ScaleW(10), screenHeight - ScaleH(50), math.Clamp(client:Health(), 0, 100) * ScaleW(2.25), ScaleH(4), Color(255, 50, 50, 255))
    ----------------------------------------------------------------
    -- Info at round start
    ----------------------------------------------------------------
    if not gameStarted then
        draw.RoundedBox(cornerRadiusSmall, (screenWidth * 0.5) - ScaleW(225), ScaleH(75), ScaleW(450), ScaleH(60), Color(10, 10, 10, 230))
        draw.SimpleText("Starting Points: " .. startingPoints, "CloseCaption_Bold", screenWidth * 0.5 + ScaleW(90), ScaleH(90), Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText("Rounds: " .. startingRounds, "CloseCaption_Bold", (screenWidth * 0.5) - ScaleW(180), ScaleH(90), Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    ----------------------------------------------------------------
    -- Center Timer (top-center)
    ----------------------------------------------------------------
    if tickTimerOver > tickCount then
        local currentTimer = math.floor((tickTimerOver - tickCount) / 66)
        local roundedBoxWidth = ScaleW(150)
        local boxX = (screenWidth * 0.5) - (roundedBoxWidth * 0.5)
        local boxY = ScaleH(75)
        local boxH = ScaleH(60)
        draw.RoundedBox(cornerRadiusSmall, boxX, boxY, roundedBoxWidth, boxH, Color(10, 10, 10, 230))
        local minutes = math.floor(currentTimer / 60)
        local seconds = currentTimer % 60
        local timeString = string.format("%d:%02d", minutes, seconds)
        draw.SimpleText(timeString, "timefont", boxX + ScaleW(30), ScaleH(73), Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    ----------------------------------------------------------------
    -- Research / Score / Team Info (right side)
    ----------------------------------------------------------------
    -- Right panel for research/mob info
    local panelW = ScaleW(350)
    local panelH = ScaleH(250) + ScaleH(250) * descriptionsEnabled
    local panelX = screenWidth - panelW
    local panelY = screenHeight - panelH
    draw.RoundedBox(cornerRadiusLarge, panelX, panelY, panelW, panelH, Color(20, 20, 20, 230))
    draw.SimpleText("Research Points:  " .. points, "ChatFont", panelX + ScaleW(20), panelY + ScaleH(10), Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("Mob Info: ", "ChatFont", panelX + ScaleW(20), panelY + ScaleH(50), Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    -- If we have a mob selected
    if boxKey ~= "" then
        local rarityNames = {
            [1] = "Common",
            [2] = "Uncommon",
            [3] = "Rare",
            [4] = "Legendary"
        }

        local formattedBoxRarity = rarityNames[boxRarity]
        print(SERVER and "server" or "client")
        print(mobs[1]["fasttorso"].name)
        local boxMobName = mobs[boxRarity][boxKey].name
        -- We'll place these lines a bit below "Mob Info"
        local textBaseY = panelY + ScaleH(80)
        draw.SimpleText("Tech Level: " .. boxLevel, "ChatFont", panelX + ScaleW(40), textBaseY, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Mob Type: " .. boxMobName, "ChatFont", panelX + ScaleW(40), textBaseY + ScaleH(30), Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Rarity: " .. formattedBoxRarity, "ChatFont", panelX + ScaleW(40), textBaseY + ScaleH(60), Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Strength: " .. boxStrength, "ChatFont", panelX + ScaleW(40), textBaseY + ScaleH(90), Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        if descriptionsEnabled == 1 then
            local mobDescription = boxKey
            -- Draw up to 15 lines of description
            for i = 1, 15 do
                local desc = GetGlobalString(mobDescription .. "_" .. i)
                if desc and desc ~= "" then draw.SimpleText(desc, "ChatFont", panelX + ScaleW(20), panelY + ScaleH(200) + ScaleH(20) * i, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP) end
            end
        end
    end

    ----------------------------------------------------------------
    -- Scoreboard (top-center)
    ----------------------------------------------------------------
    draw.RoundedBox(cornerRadiusSmall, (screenWidth * 0.5) - ScaleW(400), ScaleH(5), ScaleW(800), ScaleH(56), Color(10, 10, 10, 250))
    draw.SimpleText("Blue ", "CloseCaption_Bold", (screenWidth * 0.5) - ScaleW(370), ScaleH(20), Color(0, 80, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(team.GetScore(1), "CloseCaption_Bold", (screenWidth * 0.5) - ScaleW(300), ScaleH(20), Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("Red ", "CloseCaption_Bold", (screenWidth * 0.5) - ScaleW(170), ScaleH(20), Color(255, 50, 0, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(team.GetScore(2), "CloseCaption_Bold", (screenWidth * 0.5) - ScaleW(105), ScaleH(20), Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("Green ", "CloseCaption_Bold", (screenWidth * 0.5) + ScaleW(30), ScaleH(20), Color(0, 255, 0, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(team.GetScore(3), "CloseCaption_Bold", (screenWidth * 0.5) + ScaleW(120), ScaleH(20), Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("Yellow ", "CloseCaption_Bold", (screenWidth * 0.5) + ScaleW(230), ScaleH(20), Color(255, 255, 0, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(team.GetScore(4), "CloseCaption_Bold", (screenWidth * 0.5) + ScaleW(330), ScaleH(20), Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    ----------------------------------------------------------------
    -- Team indicator (bottom-left)
    ----------------------------------------------------------------
    local teamBoxW = ScaleW(160)
    local teamBoxH = ScaleH(50)
    local teamBoxX = ScaleW(5)
    local teamBoxY = screenHeight - ScaleH(130)
    -- Default
    local teamName = "Pick Team"
    local teamColor = Color(130, 130, 130, 255)
    if client:Team() == 1 then
        teamName = "Blue Team"
        teamColor = Color(0, 80, 255, 255)
    elseif client:Team() == 2 then
        teamName = "Red Team"
        teamColor = Color(255, 0, 0, 255)
    elseif client:Team() == 3 then
        teamName = "Green Team"
        teamColor = Color(0, 255, 0, 255)
    elseif client:Team() == 4 then
        teamName = "Yellow Team"
        teamColor = Color(255, 255, 0, 255)
    end

    draw.RoundedBox(cornerRadiusSmall, teamBoxX, teamBoxY, teamBoxW, teamBoxH, Color(10, 10, 10, 100))
    draw.SimpleText(teamName, "CloseCaption_Bold", teamBoxX + ScaleW(15), teamBoxY + ScaleH(10), teamColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    ----------------------------------------------------------------
    -- Temporary center message
    ----------------------------------------------------------------
    if tempMessage ~= "" then
        draw.SimpleText(tempMessage, "CloseCaption_Bold", screenWidth * 0.5, screenHeight * 0.3636, -- ~2.75
            tempMessageColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

hook.Add("HUDPaint", "STSHUD", HUD)
function HideHud(name)
    for _, element in pairs({"CHudHealth", "CHudBattery", "CHudAmmo", "CHudSecondaryAmmo"}) do
        if name == element then return false end
    end
end

hook.Add("HUDShouldDraw", "HideDefaultHud", HideHud)
