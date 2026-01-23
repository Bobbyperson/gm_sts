AddCSLuaFile("bonusround.lua")
AddCSLuaFile("concommands.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("teamsetup.lua")
AddCSLuaFile("cl_hud.lua")
AddCSLuaFile("cubes.lua")
AddCSLuaFile("misc.lua")
AddCSLuaFile("mobs.lua")
AddCSLuaFile("sound.lua")
AddCSLuaFile("teleports.lua")
AddCSLuaFile("net.lua")
AddCSLuaFile("testing.lua")
AddCSLuaFile("descriptions.lua")
-- AddCSLuaFile("entities/team_indicator/init.lua")
include("bonusround.lua")
include("concommands.lua")
include("shared.lua")
include("teamsetup.lua")
include("cubes.lua")
include("net.lua")
include("misc.lua")
include("mobs.lua")
include("triggers.lua")
include("sound.lua")
include("teleports.lua")
include("testing.lua")
-- include("entities/team_indicator/init.lua")
math.randomseed(os.time())
nextMap = ""
nextBR = ""
currentMap = ""
maps = {"square", "cit", "rav", "rail", "lake", "yellow", "green", "blue"}
gameState = 0
roundCounter = 0
gameStartedServer = false
-- determines loadout. returning true means override default, this might be able to be used for minigames.
-- function GM:PlayerLoadout(ply)
--     return true
-- end
hook.Add("PlayerLoadout", "Default", function(ply) return true end)
-- cvars.AddChangeCallback("sts_random_teams", function(convarName, valueOld, valueNew)
--     print("TODO: Create team door and open and close it")
-- end)
cvars.AddChangeCallback("sts_force_bonus_rounds", function(convarName, valueOld, valueNew)
    for _, ent in ipairs(ents.GetAll()) do
        if ent:GetName() == "waiting_lobby_brtoggle_lever" then
            if valueNew == "1" then
                ent:Fire("Close")
                ent:Fire("Lock")
            elseif valueNew == "0" then
                ent:Fire("Unlock")
            elseif valueNew == "-1" then
                ent:Fire("Open")
                ent:Fire("Lock")
            end
        end
    end
end)

cvars.AddChangeCallback("sts_disable_settings_buttons", function(convarName, valueOld, valueNew)
    if gameStartedServer then return end
    if valueNew == "1" then
        for _, ent in ipairs(ents.GetAll()) do
            if ent:GetName() == "waiting_lobby_ready_door" then ent:Fire("open") end
        end
    elseif valueNew == "0" then
        for _, ent in ipairs(ents.GetAll()) do
            if ent:GetName() == "waiting_lobby_ready_door" then ent:Fire("close") end
        end
    end
end)

cvars.AddChangeCallback("sts_starting_points", function(convarName, valueOld, valueNew)
    updateSettingsToClients(valueNew, GetConVar("sts_total_rounds"):GetInt())
    if valueNew == "80" then
        for _, ent in ipairs(ents.GetAll()) do
            if ent:GetName() == "waiting_startpnt_up" then ent:Fire("lock") end
        end
    else
        for _, ent in ipairs(ents.GetAll()) do
            if ent:GetName() == "waiting_startpnt_up" then ent:Fire("unlock") end
        end
    end

    if valueNew == "5" then
        for _, ent in ipairs(ents.GetAll()) do
            if ent:GetName() == "waiting_startpnt_down" then ent:Fire("lock") end
        end
    else
        for _, ent in ipairs(ents.GetAll()) do
            if ent:GetName() == "waiting_startpnt_down" then ent:Fire("unlock") end
        end
    end
end)

cvars.AddChangeCallback("sts_total_rounds", function(convarName, valueOld, valueNew)
    valueNew = tonumber(valueNew)
    updateSettingsToClients(GetConVar("sts_starting_points"):GetInt(), valueNew)
    if valueNew >= 24 then
        for _, ent in ipairs(ents.GetAll()) do
            if ent:GetName() == "waiting_score_up" then ent:Fire("lock") end
        end
    else
        for _, ent in ipairs(ents.GetAll()) do
            if ent:GetName() == "waiting_score_up" then ent:Fire("unlock") end
        end
    end

    if valueNew <= 1 then
        for _, ent in ipairs(ents.GetAll()) do
            if ent:GetName() == "waiting_score_down" then ent:Fire("lock") end
        end
    else
        for _, ent in ipairs(ents.GetAll()) do
            if ent:GetName() == "waiting_score_down" then ent:Fire("unlock") end
        end
    end
end)

function lockButtonsAfterGameStart()
    for _, ent in ipairs(ents.GetAll()) do
        if ent:GetName() == "waiting_score_up" then
            ent:Fire("lock")
        elseif ent:GetName() == "waiting_score_down" then
            ent:Fire("lock")
        elseif ent:GetName() == "waiting_startpnt_down" then
            ent:Fire("lock")
        elseif ent:GetName() == "waiting_startpnt_up" then
            ent:Fire("lock")
        end
    end
end

cvars.AddChangeCallback("sts_minimum_players", function(convarName, valueOld, valueNew) shouldStartLeverBeLocked() end)
function getAmountOfTeamedPlayers()
    local teamedPlayers = 0
    for i, teamLoop in ipairs(team.GetAllTeams()) do
        if team.GetName(i) ~= "Spectator" and team.GetName(i) ~= "Empty" then
            for _, _ in ipairs(team.GetPlayers(i)) do
                teamedPlayers = teamedPlayers + 1
            end
        end
    end
    return teamedPlayers
end

function shouldStartLeverBeLocked()
    -- PrintMessage(HUD_PRINTTALK, "Checking!")
    local teamedPlayers = getAmountOfTeamedPlayers()
    local totalPlayers = player.GetCount()
    local minimumRequired = GetConVar("sts_minimum_players"):GetInt()
    local randomizedTeams = GetConVar("sts_random_teams"):GetInt()
    for _, ent in ipairs(ents.GetAll()) do
        if ent:GetName() == "waiting_lobby_readylever" then
            if (teamedPlayers >= minimumRequired or (randomizedTeams and totalPlayers >= minimumRequired)) and gameStartedServer == false then
                ent:Fire("Unlock")
                -- PrintMessage(HUD_PRINTTALK, "Unlocked!")
                return false
            else
                ent:Fire("Lock")
                -- PrintMessage(HUD_PRINTTALK, "Locked!")
                return true
            end
        end

        if ent:GetName() == "startdelay_light_r" then
            if (teamedPlayers < minimumRequired or (randomizedTeams and totalPlayers < minimumRequired)) and gameStartedServer == false then
                ent:Fire("TurnOn")
            else
                ent:Fire("TurnOff")
            end
        end

        if ent:GetName() == "startdelay_light_g" then
            if (teamedPlayers >= minimumRequired or (randomizedTeams and totalPlayers >= minimumRequired)) or gameStartedServer == true then
                ent:Fire("TurnOn")
            else
                ent:Fire("TurnOff")
            end
        end
    end
end

function getChosenBonusRounds()
    local lever
    local leverClass
    local leverState
    local bonusRoundDesired
    local bonusRounds = {"waiting_lobby_mapleverb_lake", "waiting_lobby_mapleverb_blue", "waiting_lobby_mapleverb_green", "waiting_lobby_mapleverb_boomstick", "waiting_lobby_mapleverb_ctf", "waiting_lobby_mapleverb_battery", "waiting_lobby_mapleverb_ravsurv", "waiting_lobby_mapleverb_rav", "waiting_lobby_mapleverb_cit", "waiting_lobby_mapleverb_square"}
    local selectedBonusRounds = {}
    for _, entity in ipairs(ents.GetAll()) do
        if entity:GetName() == "waiting_lobby_brtoggle_lever" then
            lever = entity
        else
            for _, bonusRoundLever in ipairs(bonusRounds) do
                if entity:GetName() == bonusRoundLever then
                    if entity:GetClass() == "func_door" or entity:GetClass() == "func_door_rotating" then
                        bonusRoundDesired = entity:GetInternalVariable("m_toggle_state") == 0
                    elseif entity:GetClass() == "prop_door_rotating" then
                        bonusRoundDesired = entity:GetInternalVariable("m_eDoorState") ~= 0
                    else
                        bonusRoundDesired = false
                    end

                    if bonusRoundDesired == false then table.insert(selectedBonusRounds, entity:GetName()) end
                end
            end
        end
    end

    -- https://wiki.facepunch.com/gmod/Entity:GetInternalVariable
    leverClass = lever:GetClass()
    if leverClass == "func_door" or leverClass == "func_door_rotating" then
        leverState = lever:GetInternalVariable("m_toggle_state") == 0
    elseif leverClass == "prop_door_rotating" then
        leverState = lever:GetInternalVariable("m_eDoorState") ~= 0
    else
        leverState = false
    end

    -- lever up means the door is closed (false) and bonus rounds should be on. 
    if leverState == false then
        return selectedBonusRounds
    else
        return {}
    end
end

function getChosenMaps()
    local mapDesired
    local mapLevers = {"waiting_lobby_maplever_square", "waiting_lobby_maplever_cit", "waiting_lobby_maplever_rav", "waiting_lobby_maplever_rail", "waiting_lobby_maplever_lake", "waiting_lobby_maplever_yellow", "waiting_lobby_maplever_green", "waiting_lobby_maplever_blue"}
    local selectedMaps = {}
    for _, entity in ipairs(ents.GetAll()) do
        if entity:GetName() ~= "waiting_lobby_brtoggle_lever" then
            for _, bonusRoundLever in ipairs(mapLevers) do
                if entity:GetName() == bonusRoundLever then
                    if entity:GetClass() == "func_door" or entity:GetClass() == "func_door_rotating" then
                        mapDesired = entity:GetInternalVariable("m_toggle_state") == 0
                    elseif entity:GetClass() == "prop_door_rotating" then
                        mapDesired = entity:GetInternalVariable("m_eDoorState") ~= 0
                    else
                        mapDesired = false
                    end

                    if mapDesired == false then table.insert(selectedMaps, entity:GetName()) end
                end
            end
        end
    end

    local goodSelectedMaps = {}
    for _, k in ipairs(selectedMaps) do
        table.insert(goodSelectedMaps, getMapFromWhatever(k))
    end
    return goodSelectedMaps
end

function GM:PlayerInitialSpawn(ply)
    ply:SetMaxHealth(100)
    ply:SetHealth(100)
    ply:SetRunSpeed(400)
    ply:SetPlayerColor(Vector(0.0, 0.0, 0.0))
    setTeamFull(ply, 0)
    if GetConVar("sts_disable_settings_buttons"):GetInt() == 0 then
        for _, ent in ipairs(ents.GetAll()) do
            if ent:GetName() == "waiting_lobby_ready_door" then ent:Fire("close") end
        end
    end

    if game.MaxPlayers() > 16 then ply:PrintMessage(HUD_PRINTTALK, "WARNING! You are playing on a server which has more than 16 playerslots! This gamemode was not designed with more than 16 players in mind and you WILL run into bugs.") end
    if ply:IsListenServerHost() and IsMounted("ep2") then
        ply:PrintMessage(HUD_PRINTTALK, "You appear to have half life 2 episode 2 mounted. Episodic content has been enabled. If any players do not have episode 2 mounted, please set sts_episodic_content to 0 in console.")
        GetConVar("sts_episodic_content"):SetInt(1)
    end

    if gameStartedServer then sendStartToPlayers() end
    updateSettingsToClients(GetConVar("sts_starting_points"):GetInt(), GetConVar("sts_total_rounds"):GetInt())
    if math.random(1, 100) == 1 then playGlobalSound("sts_announcer/playerjoin.ogg") end
end

hook.Add("PlayerSpawn", "UniversalPlayerSpawn", function(ply)
    -- this needs to wait a tick for some reason???? otherwise it doesn't work.
    -- it is supremely fucked up how many things are fixed by making them wait
    -- one fucking tick, 
    timer.Simple(1 / 66, function()
        setTeamFull(ply, ply:Team())
        ply:SetNoCollideWithTeammates(true)
    end)

    ply:SetupHands()
end)

function teleportToTeamSpawn(ply)
    local teams = {"waiting_bluetp", "waiting_redtp", "waiting_greentp", "waiting_yellowtp"}
    ply:SetHealth(100)
    local spawnPoint = teams[ply:Team()]
    for _, ent in ipairs(ents.GetAll()) do
        if ent:GetName() == spawnPoint then
            ply:SetPos(ent:GetPos())
            ply:SetEyeAngles(ent:GetAngles())
            break
        end
    end
end

function GM:PlayerSetHandsModel(ply, ent)
    local simplemodel = player_manager.TranslateToPlayerModelName(ply:GetModel())
    local info = player_manager.TranslatePlayerHands(simplemodel)
    if info then
        ent:SetModel(info.model)
        ent:SetSkin(info.skin)
        ent:SetBodyGroups(info.body)
    end
end

function spawnTeams()
    for _, ply in ipairs(player.GetAll()) do
        ply:Spawn()
    end
end

function GM:PlayerUse(ply, ent)
    if ent:GetName() == "waiting_blueteambutt" then
        -- setTeamFull(ply, 1)
        ply:ConCommand("set_team 1")
    elseif ent:GetName() == "waiting_redteambutt" then
        -- setTeamFull(ply, 2)
        ply:ConCommand("set_team 2")
    elseif ent:GetName() == "waiting_greenteambutt" then
        -- setTeamFull(ply, 3)
        ply:ConCommand("set_team 3")
    elseif ent:GetName() == "waiting_yellowteambutt" then
        -- setTeamFull(ply, 4)
        ply:ConCommand("set_team 4")
    end
end

-- when holding something
function GM:OnPlayerPhysicsPickup(ply, ent)
    local enty = ent:GetName()
    local boxEnt
    if string.sub(enty, -4, -2) == "box" then
        for _, teamID in pairs(teams) do
            for _, box in pairs(teamID.cubes) do
                if box.entity == enty then boxEnt = box end
            end
        end

        if boxEnt then
            -- PrintMessage(HUD_PRINTTALK, boxEnt.entity)
            SendBoxInfoToPlayer(ply, boxEnt)
        end
    end

    if string.sub(ent:GetName(), 0, 4) == "flag" then
        ply:SetWalkSpeed(100)
        ply:SetRunSpeed(125)
    end
end

function GM:OnPlayerPhysicsDrop(ply, ent)
    ClearBox(ply)
    if string.sub(ent:GetName(), 0, 4) == "flag" then
        ply:SetWalkSpeed(200)
        ply:SetRunSpeed(400)
    end
end

-- checks to see if server is empty on player disconnects
function GM:PlayerDisconnected(ply)
    shouldStartLeverBeLocked()
    print("A player has disconnected")
    print(ply:Name() .. " has left the server.")
    if gameStartedServer then timer.Simple(10, allgonecheck) end
    if gameState == 0 then shouldGameStart() end
    if math.random(1, 100) == 1 then playGlobalSound("sts_announcer/playerleave.ogg") end
end

function GM:PlayerConnect(name, ip)
    shouldStartLeverBeLocked()
end

-- runs endtimerstart() if server is empty
function allgonecheck()
    -- print(tonumber(player.GetCount()))
    if tonumber(player.GetCount()) == 0 then
        print("Server Empty")
        endtimerstart()
    else
        print("Server Not Empty")
    end
end

-- creates timer to run gamereset
function endtimerstart()
    timer.Create("endtimer", 50, 1, gameReset)
end

-- resets the game by reloading the map
function gameReset()
    RunConsoleCommand("changelevel", "gm_sts") -- should've done this from the beginning
end

function addTeamPoints(teamName, change)
    local points
    local teamID = getTeamIDFromName(teamName)
    for _, entity in ipairs(ents.GetAll()) do
        if entity:GetName() == (teamName .. "_points") then
            points = entity:GetNwInt("researchPoints")
            entity:SetNWInt("researchPoints", points + change)
            points = points + change
        end
    end

    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == teamID then ply:SetNWInt("researchPoints", points) end
    end
end

function beginTeamAssignment()
    -- needs significant testing
    hook.Add("OnEntityCreated", "AssignTeams", function(ent)
        if not ent:IsValid() or not ent:IsNPC() then return end
        local npcClass = ent:GetClass()
        timer.Simple(3 / 66, function()
            ent = ents.GetByIndex(ent:EntIndex())
            if not ent:IsValid() or not ent:IsNPC() then return end
            if ent:GetName() ~= "" then ent = AssignTeam(ent, ent:GetName(), true) end
        end)

        -- name assigned after 1 tick
        timer.Simple(6 / 66, function()
            -- if (
            -- (npcClass == "npc_headcrab" or
            -- npcClass == "npc_headcrab_fast" or
            -- npcClass == "npc_headcrab_black" or
            -- npcClass == "npc_manhack") and
            -- ent:GetName() == "") or
            -- string.find(ent:GetName(), "notp") or
            -- npcClass == "npc_turret_floor" then return end -- mob was spawned by already existing mob and does not need teleporting
            -- reacquire ent because it might have changed
            ent = ents.GetByIndex(ent:EntIndex())
            if not ent:IsValid() or not ent:IsNPC() then return end
            if npcClass == "npc_turret_floor" then return end
            if ent:GetName() == "" then return end
            if string.find(ent:GetName(), "notp") then return end
            -- i forgot why this is waiting an extra tick
            timer.Simple(2 / 66, function()
                -- PrintMessage(HUD_PRINTTALK, "teleporting!!!!! " .. ent:GetName() .. " " .. npcClass)
                local randspawnpoint = math.random(1, 5)
                -- print("teleporting to " .. randspawnpoint)
                -- print("name is " .. ent:GetName())
                -- print(string.sub(string.lower(ent:GetName()), 1, string.find(string.lower(ent:GetName()), "team") - 1))
                ent:SetPos(nextMapSpawnLocations[string.sub(string.lower(ent:GetName()), 1, string.find(string.lower(ent:GetName()), "team") - 1)][randspawnpoint][1]) -- TODO: frequently does nil values
                ent:SetAngles(nextMapSpawnLocations[string.sub(string.lower(ent:GetName()), 1, string.find(string.lower(ent:GetName()), "team") - 1)][randspawnpoint][2])
                ent:SetMaxLookDistance(4000)
            end)
        end)

        if npcClass == "npc_poisonzombie" then
            timer.Simple(10 / 66, function()
                ent = ents.GetByIndex(ent:EntIndex())
                local poisonZombieTeam = ent:GetName()
                -- Start a timer that runs every second
                -- print("Starting poison zombie check" .. ent:EntIndex())
                timer.Create("CheckForPoison" .. ent:EntIndex(), 1 / 66, 6000, function()
                    if not ent:IsValid() or ent:EntIndex() == 0 then
                        timer.Remove("CheckForPoison" .. ent:EntIndex())
                        return
                    end

                    local foundEntities = ents.FindInSphere(ent:GetPos(), 100) -- adjust radius as necessary
                    for _, foundEnt in pairs(foundEntities) do
                        if foundEnt:GetClass() == "npc_headcrab_poison" and foundEnt:GetName() == "" then
                            local teamColors = {
                                ["redteam"] = "255 0 0",
                                ["blueteam"] = "0 0 255",
                                ["yellowteam"] = "255 255 0",
                                ["greenteam"] = "0 255 0"
                            }

                            -- PrintMessage(HUD_PRINTTALK, "found poison zombie")
                            AssignTeam(foundEnt, poisonZombieTeam, false)
                            foundEnt:SetMaxLookDistance(4000)
                            foundEnt:SetKeyValue("rendercolor", teamColors[poisonZombieTeam:lower()])
                        end
                    end
                end)
            end)
        end

        if npcClass == "npc_metropolice" then
            timer.Simple(10 / 66, function()
                ent = ents.GetByIndex(ent:EntIndex())
                local metrocopTeam = ent:GetName()
                -- Start a timer that runs every second
                -- PrintMessage(HUD_PRINTTALK, "Starting metrocop check" .. ent:EntIndex())
                timer.Create("CheckForManhacks" .. ent:EntIndex(), 1 / 66, 6000, function()
                    if not ent:IsValid() or ent:EntIndex() == 0 then
                        timer.Remove("CheckForManhacks" .. ent:EntIndex())
                        return
                    end

                    local foundEntities = ents.FindInSphere(ent:GetPos(), 100) -- adjust radius as necessary
                    for _, foundEnt in pairs(foundEntities) do
                        if foundEnt:GetClass() == "npc_manhack" and foundEnt:GetName() == "" then
                            local teamColors = {
                                ["redteam"] = "255 0 0",
                                ["blueteam"] = "0 0 255",
                                ["yellowteam"] = "255 255 0",
                                ["greenteam"] = "0 255 0"
                            }

                            -- PrintMessage(HUD_PRINTTALK, "manhack found!")
                            AssignTeam(foundEnt, metrocopTeam, false)
                            foundEnt:SetMaxLookDistance(4000)
                            foundEnt:SetKeyValue("rendercolor", teamColors[metrocopTeam:lower()])
                            -- PrintMessage(HUD_PRINTTALK, "Assigned manhack team.")
                            timer.Remove("CheckForManhacks" .. ent:EntIndex())
                        end
                    end
                end)
            end)
        end
    end)
end

function endTeamAssignment()
    hook.Remove("OnEntityCreated", "AssignTeams")
end

hook.Add("OnNPCKilled", "TrackZombieDeath", function(npc)
    local zombieTypes = {"npc_zombie", "npc_zombie_torso", "npc_fastzombie", "npc_poisonzombie"}
    for _, type in pairs(zombieTypes) do
        if npc:GetClass() == type and npc:GetName() ~= "" then
            local deadZombiePos = npc:GetPos()
            local deadZombieTeam = npc:GetName()
            -- timer might be necessary as headcrab might not exist on same tick
            timer.Create("CheckForHeadcrab" .. npc:EntIndex(), 1 / 66, 3, function()
                -- print("Death headcrab check.")
                local foundEntities = ents.FindInSphere(deadZombiePos, 100) -- radius needs adjusting
                for _, ent in pairs(foundEntities) do
                    if (ent:GetClass() == "npc_headcrab" or ent:GetClass() == "npc_headcrab_fast" or ent:GetClass() == "npc_headcrab_black") and ent:GetName() == "" then
                        local teamColors = {
                            ["redteam"] = "255 0 0",
                            ["blueteam"] = "0 0 255",
                            ["yellowteam"] = "255 255 0",
                            ["greenteam"] = "0 255 0"
                        }

                        ent:SetMaxLookDistance(4000)
                        ent:SetKeyValue("rendercolor", teamColors[deadZombieTeam:lower()])
                        AssignTeam(ent, deadZombieTeam, false)
                        --ent:SetKeyValue("rendercolor", "255 30 30") -- ! temp
                        -- PrintMessage(HUD_PRINTTALK, "Assigned headcrab team.")
                    end
                end

                if not npc:IsValid() then timer.Remove("CheckForHeadcrab" .. npc:EntIndex()) end
            end)
        end
    end
end)

function AssignTeam(ent, teamInput, tpDesired)
    if not ent:IsValid() or not ent:IsNPC() or ent:EntIndex() == 0 then return end
    local npcColors = {"redteam", "blueteam", "greenteam", "yellowteam"}
    local validInput = false
    -- warn if teamInput is not valid team
    for _, teamName in pairs(npcColors) do
        if string.find(teamInput, teamName) then validInput = true end
    end

    if not validInput then print("Warning! " .. teamInput .. " is not a valid team! NPC Class is " .. ent:GetClass() .. " with name " .. ent:GetName()) end
    local teamEnts = {}
    -- PrintMessage(HUD_PRINTTALK, ent:GetName() .. ent:GetClass() .. ", " .. teamInput)
    -- for some reason which I cannot diagnose or explain despite my best attempts, 
    -- this check is always true. running the same check in game is not always true. i don't get it!
    -- Too Bad!
    -- print("1Name is " .. ent:GetName())
    ent:SetName(teamInput)
    ent:SetNWString("wallhack_col", teamInput)
    -- print("2Name is " .. ent:GetName())
    for i, teamName in pairs(npcColors) do
        teamEnts[i] = ents.FindByName(teamName)
    end

    for i, teamName in pairs(npcColors) do
        for _, teamEntity in pairs(teamEnts[i]) do
            -- to avoid self-love
            if ent ~= teamEntity and teamEntity:IsNPC() then
                if string.find(ent:GetName(), teamName) then
                    ent:AddEntityRelationship(teamEntity, D_LI, 10)
                    teamEntity:AddEntityRelationship(ent, D_LI, 10)
                    -- print(ent:GetClass() .. ent:GetName() .. " now likes " .. teamEntity:GetClass() .. teamEntity:GetName() .. "!")
                    if not string.find(ent:GetName(), teamName) then PrintMessage(HUD_PRINTTALK, "Warning! Opposite teams like each other!!! " .. ent:GetName() .. " " .. teamEntity:GetName()) end
                else
                    ent:AddEntityRelationship(teamEntity, D_HT, 10)
                    teamEntity:AddEntityRelationship(ent, D_HT, 10)
                    -- print(ent:GetClass() .. ent:GetName() .. " now hates " .. teamEntity:GetClass() .. teamEntity:GetName() .. "!")
                    if string.find(ent:GetName(), teamName) then PrintMessage(HUD_PRINTTALK, "Warning! Same teams hate each other!!! " .. ent:GetName() .. " " .. teamEntity:GetName()) end
                end
            end

            -- the following is REALLY slow and is an attempted bodge fix for the team self hatred. this might cause huge lag for games with lots of mobs!
            -- not doing team hatred because there doesn't seem to be any issue with that currently
            -- ! cannot emphasize enough how much this sucks, runs on every mob for every mob spawn this is O(n^2)
            -- ! this is some dumbass shit that i hate so much oh my god look at issue #4
            -- ! when i eventually have every mob spawned by lua and not map entities, if this issue still persists i don't know what i'll do
            for _, teamEntity2 in pairs(teamEnts[i]) do
                if teamEntity ~= teamEntity2 and teamEntity:IsNPC() and teamEntity2:IsNPC() then
                    teamEntity:AddEntityRelationship(teamEntity2, D_LI, 10)
                    teamEntity2:AddEntityRelationship(teamEntity, D_LI, 10)
                end
            end
        end
    end

    if not tpDesired then
        ent:SetName(teamInput .. "notp")
        -- PrintMessage(HUD_PRINTTALK, ent:GetClass() .. " " .. ent:GetName() .. " has been assigned to " .. teamInput .. " and will not be teleported.")
    end
    return ent
end

function roundLimitChange(amount)
    local roundLimitConvar = GetConVar("sts_total_rounds")
    local roundLimit = roundLimitConvar:GetInt()
    roundLimitConvar:SetInt(roundLimit + amount)
end

function startingPointsChange(amount)
    local startingPointsConvar = GetConVar("sts_starting_points")
    local startingPoints = startingPointsConvar:GetInt()
    startingPointsConvar:SetInt(startingPoints + (amount * 5))
end

function startGame()
    PrintMessage(HUD_PRINTCENTER, "Ready!")
    RunConsoleCommand("sv_hibernate_think", "1")
    randomizeTeams(GetConVar("sts_random_teams"):GetInt())
    gameStartedServer = true
    sendStartToPlayers()
    nextMap = chooseNextMap()
    nextBR = chooseBonusRound()
    setNextMapScreen(getMapScreen(nextMap))
    beginPlayingMainTrack()
    for i = 1, 4 do
        teams[i].points = GetConVar("sts_starting_points"):GetInt()
        SendPointsToTeamMembers(i)
    end

    startLobbySpawn()
end

function randomizeTeams(mode)
    if mode == 0 then -- no need to randomize teams
        return
    end

    local players = player.GetAll()
    local i = 1
    if #players > 8 then mode = 1 end
    local teamCount = mode * 2
    if mode == 2 then
        while #players > 0 do
            local playerIndex = math.random(1, #players)
            local teamID = i % teamCount
            if i % teamCount == 0 then
                setTeamFull(players[playerIndex], 4)
            else
                setTeamFull(players[playerIndex], teamID)
            end

            table.remove(players, playerIndex)
            i = i + 1
        end
    else
        while #players > 0 do
            local playerIndex = math.random(1, #players)
            if i % teamCount == 0 then
                setTeamFull(players[playerIndex], 2)
            else
                setTeamFull(players[playerIndex], 1)
            end

            table.remove(players, playerIndex)
            i = i + 1
        end
    end
end

function upgradeABox(cubeName)
    -- A lot of checks can be skipped like team validation as that essentially handled
    -- by the game world itself, and if bypassed (i.e. thru noclip), its probably for a good reason.
    -- The only checks required should be checking affordability and tech level
    -- print("upgrading")
    local desiredCube
    local availablePoints
    local currentTeam
    local teamID
    for i, teamName in ipairs(teams) do
        for _, cube in pairs(teamName.cubes) do
            if cube.entity == cubeName then
                currentTeam = teamName
                desiredCube = cube
                teamID = i
                availablePoints = teamName.points
                break
            end
        end
    end

    if desiredCube.level == 5 then
        for _, ply in ipairs(player.GetAll()) do
            if ply:Team() == teamID then ply:PrintMessage(HUD_PRINTTALK, "Max tech level reached!") end
        end
        return
    end

    for _, cube in pairs(currentTeam.cubes) do
        if cube ~= desiredCube and cube.level < desiredCube.level then
            for _, ply in ipairs(player.GetAll()) do
                if ply:Team() == teamID then ply:PrintMessage(HUD_PRINTTALK, "Tech level not available!") end
            end
            return
        end
    end

    if desiredCube:canUpgrade(availablePoints) then
        currentTeam.points = currentTeam.points - (desiredCube.level * 6) -- this needs to come first because the level will update in the next line
        desiredCube:upgrade()
        -- print("actually upgrading")
    else
        for _, ply in ipairs(player.GetAll()) do
            if ply:Team() == teamID then ply:PrintMessage(HUD_PRINTTALK, "Cannot Afford!") end
        end
        return
    end

    if currentTeam.cubes["cube1"].level == currentTeam.cubes["cube2"].level and currentTeam.cubes["cube3"].level == currentTeam.cubes["cube4"].level and currentTeam.cubes["cube2"].level == currentTeam.cubes["cube3"].level then
        for _, ply in ipairs(player.GetAll()) do
            if ply:Team() == teamID then ply:PrintMessage(HUD_PRINTTALK, "New Tech Level!") end
        end

        local funny = math.random(1, 100)
        if funny == 1 then
            playGlobalSound("sts_announcer/newtechlevel_funny.wav", teamID)
        else
            local variant = math.random(1, 3)
            playGlobalSound("sts_announcer/newtechlevel" .. variant .. ".wav", teamID)
        end
    end

    -- lazy
    for teamIndex = 1, 4 do
        SendPointsToTeamMembers(teamIndex)
    end
end

function randomizeABox(cubeName)
    -- PrintMessage(HUD_PRINTTALK, "Randomizing " .. cubeName .. "!")
    local desiredCube
    local availablePoints
    local teamID
    for i, teamName in ipairs(teams) do
        for _, cube in pairs(teamName.cubes) do
            if cube.entity == cubeName then
                desiredCube = cube
                teamID = i
                availablePoints = teamName.points
                break
            end
        end
    end

    if availablePoints <= 0 then
        for _, ply in ipairs(player.GetAll()) do
            if ply:Team() == teamID then ply:PrintMessage(HUD_PRINTTALK, "Cannot afford!") end
        end
        return
    end

    if desiredCube then
        desiredCube:randomize()
        for _, teamName in ipairs(teams) do
            for _, cube in pairs(teamName.cubes) do
                if cube.entity == cubeName then
                    teamName.points = teamName.points - 1
                    break
                end
            end
        end
    else
        PrintMessage(HUD_PRINTTALK, "Could not find cube in randomize func! Report this in the discord please!")
    end

    -- lazy
    for teamIndex = 1, 4 do
        SendPointsToTeamMembers(teamIndex)
    end
end

function chooseNextMap()
    local options = getChosenMaps()
    if #options == 1 then return options[1] end
    -- remove last map from options
    for i, map in ipairs(options) do
        if map == nextMap then table.remove(options, i) end
    end

    local map = options[math.random(#options)]
    return map
end

function chooseBonusRound()
    local options = getChosenBonusRounds()
    if options == {} then return {} end
    if #options == 1 then return options[1] end
    for i, br in ipairs(options) do
        if br == nextBR then table.remove(options, i) end
    end

    local bonusRound = options[math.random(#options)]
    return bonusRound
end

function setNextMapScreen(map)
    local waitingScreens = {"waiting_screen_mapblue", "waiting_screen_mapyellow", "waiting_screen_mapgreen", "waiting_screen_maplake", "waiting_screen_maprail", "waiting_screen_maprav", "waiting_screen_mapcit", "waiting_screen_mapsquare"}
    for _, ent in ipairs(ents.GetAll()) do
        for _, mapScreen in ipairs(waitingScreens) do
            if ent:GetName() == map then
                ent:Fire("Alpha", 255)
            elseif ent:GetName() == mapScreen then
                ent:Fire("Alpha", 0)
            end
        end
    end
end

function getMapFromWhatever(whatever)
    local mapLevers = {
        ["waiting_lobby_maplever_square"] = "square",
        ["waiting_lobby_maplever_cit"] = "cit",
        ["waiting_lobby_maplever_rav"] = "rav",
        ["waiting_lobby_maplever_rail"] = "rail",
        ["waiting_lobby_maplever_lake"] = "lake",
        ["waiting_lobby_maplever_yellow"] = "yellow",
        ["waiting_lobby_maplever_green"] = "green",
        ["waiting_lobby_maplever_blue"] = "blue"
    }

    if mapLevers[whatever] then return mapLevers[whatever] end
    local mapScreens = {
        ["waiting_screen_mapblue"] = "blue",
        ["waiting_screen_mapyellow"] = "yellow",
        ["waiting_screen_mapgreen"] = "green",
        ["waiting_screen_maplake"] = "lake",
        ["waiting_screen_maprail"] = "rail",
        ["waiting_screen_maprav"] = "rav",
        ["waiting_screen_mapcit"] = "cit",
        ["waiting_screen_mapsquare"] = "square"
    }

    if mapScreens[whatever] then return mapScreens[whatever] end
end

function getMapScreen(map)
    local info = {
        ["blue"] = "waiting_screen_mapblue",
        ["yellow"] = "waiting_screen_mapyellow",
        ["green"] = "waiting_screen_mapgreen",
        ["lake"] = "waiting_screen_maplake",
        ["rail"] = "waiting_screen_maprail",
        ["rav"] = "waiting_screen_maprav",
        ["cit"] = "waiting_screen_mapcit",
        ["square"] = "waiting_screen_mapsquare"
    }
    return info[map]
end

function roundReset()
    -- PrintMessage(HUD_PRINTTALK, "Resetting round!")
    roundCounter = roundCounter + 1
    local highestscore = 0
    for _, teamID in ipairs(getPlayingTeams()) do
        if team.GetScore(teamID) > highestscore then highestscore = team.GetScore(teamID) end
    end

    if highestscore >= GetConVar("sts_total_rounds"):GetInt() then
        gameOver()
    elseif roundCounter % GetConVar("sts_bonus_round_interval"):GetInt() == 0 and #getChosenBonusRounds() ~= 0 then
        -- cannot check if table equal to empty table
        for _, ply in ipairs(player.GetAll()) do
            teleportToTeamSpawn(ply)
        end

        doBonusRound()
    else
        unmuteMainTrack()
        for _, ply in ipairs(player.GetAll()) do
            teleportToTeamSpawn(ply)
        end
    end
end

function ReadyLeverPulled(teamName)
    playGlobalSound("sts_announcer/" .. teamName .. "_ready.wav")
    shouldGameStart()
end

function shouldGameStart()
    local levers = {"waiting_blue_ready_lever", "waiting_red_ready_lever", "waiting_green_ready_lever", "waiting_yellow_ready_lever"}
    local doors = {"waiting_blue_door", "waiting_red_door", "waiting_green_door", "waiting_yellow_door"}
    local pulled = 0
    local required = 0
    for i = 1, 4 do
        if #team.GetPlayers(i) > 0 then required = required + 1 end
    end

    for _, ent in ipairs(ents.GetAll()) do
        for _, lever in ipairs(levers) do
            if ent:GetName() == lever and ent:GetInternalVariable("m_toggle_state") == 0 then pulled = pulled + 1 end
        end
    end

    if required <= pulled then
        gameState = 1
        SendServerMessage("All Teams Ready!", Color(255, 255, 255))
        timer.Simple(5, function() SendServerMessage("Fight begins in 5", Color(255, 255, 255)) end)
        timer.Simple(6, function() SendServerMessage("Fight begins in 4", Color(255, 255, 255)) end)
        timer.Simple(7, function() SendServerMessage("Fight begins in 3", Color(255, 255, 255)) end)
        timer.Simple(8, function() SendServerMessage("Fight begins in 2", Color(255, 255, 255)) end)
        timer.Simple(9, function() SendServerMessage("Fight begins in 1", Color(255, 255, 255)) end)
        timer.Simple(10, function() SendServerMessage("Fight!", Color(255, 255, 255), 3) end)
        timer.Simple(11.1, function()
            beginFight()
            timer.Simple(1 / 66, function()
                for _, ent in ipairs(ents.GetAll()) do
                    for _, lever in ipairs(levers) do
                        if ent:GetName() == lever then ent:Fire("close") end
                    end

                    for _, door in ipairs(doors) do
                        if ent:GetName() == door then ent:Fire("close") end
                    end
                end

                gameState = 0
            end)
        end)
    end
end

function beginFight()
    PrintMessage(HUD_PRINTTALK, "Fight!")
    fillNextSpawns()
    beginTeamAssignment()
    muteMainTrack()
    -- teleport to new shit
    stopLobbySpawn()
    startGameSpawn()
    setupMap(nextMap)
    enableNPCWallhacksGlobally()
    local soundTrack
    local suddenDeath = false
    for _, ent in ipairs(ents.GetAll()) do
        if ent:GetName() == "map_push_red" then ent:Fire("Enable") end
        if ent:GetName() == "map_push_blue" then ent:Fire("Enable") end
        if ent:GetName() == "map_push_green" then ent:Fire("Enable") end
        if ent:GetName() == "map_push_yellow" then ent:Fire("Enable") end
    end

    if math.random(1, 2) == 1 then
        soundTrack = playGlobalSound("sts_music/brane_scan.wav")
    else
        soundTrack = playGlobalSound("sts_music/cp_violation.wav")
    end

    for _, ent in ipairs(ents.FindByClass("info_teleport_destination")) do
        for i = 1, 4 do
            for j, teammate in ipairs(team.GetPlayers(i)) do
                if ent:GetName() == ("map" .. nextMap .. "_player_" .. getTeamNameFromID(i) .. "tpdest" .. tostring(j)) then
                    teammate:SetPos(ent:GetPos())
                    teammate:SetEyeAngles(ent:GetAngles())
                end
            end
        end
    end

    -- start spawning motherfuckers
    local teamsToSpawn = getPlayingTeams()
    local teamMobs = {} -- {1 = ..., 4 = ...}
    local delay
    local largestDelay = 0
    for _, id in pairs(teamsToSpawn) do
        PrintTable(teams[id].spawners)
        for _, spawner in ipairs(teams[id].spawners) do
            if teamMobs[id] == nil then
                teamMobs[id] = spawner[1].mob:getSpawns(id, spawner[1].strength)
            else
                TableConcat(teamMobs[id], spawner[1].mob:getSpawns(id, spawner[1].strength))
            end
        end
    end

    for i, mobs in pairs(teamMobs) do
        delay = 0
        for _, mob in ipairs(mobs) do
            delay = delay + mob[2]
            -- if mob[3] then
            --     timer.Simple(delay, mob[3](getTeamNameFromID(i), Vector(0,0,0)))
            -- else
            timer.Simple(delay, function() mob[1]:Fire("ForceSpawn") end)
            -- end
        end

        if delay > largestDelay then largestDelay = delay end
    end

    local alive = {}
    for _, id in pairs(teamsToSpawn) do
        if id == 1 then
            alive["blueteam"] = 0
        elseif id == 2 then
            alive["redteam"] = 0
        elseif id == 3 then
            alive["greenteam"] = 0
        elseif id == 4 then
            alive["yellowteam"] = 0
        end
    end

    -- PrintMessage(HUD_PRINTTALK, "waiting " .. delay .. " seconds")
    local winner
    local formattedWinner = {
        ["redteam"] = "Red",
        ["blueteam"] = "Blue",
        ["greenteam"] = "Green",
        ["yellowteam"] = "Yellow"
    }

    local winnerColor = {
        ["redteam"] = Color(255, 0, 0),
        ["blueteam"] = Color(0, 0, 255),
        ["greenteam"] = Color(0, 255, 0),
        ["yellowteam"] = Color(255, 255, 0)
    }

    local winnerShorter = {
        ["redteam"] = "red",
        ["blueteam"] = "blue",
        ["greenteam"] = "green",
        ["yellowteam"] = "yellow"
    }

    timer.Simple(largestDelay, function()
        for _, ent in ipairs(ents.GetAll()) do
            if ent:GetName() == "map_push_red" then ent:Fire("Disable") end
            if ent:GetName() == "map_push_blue" then ent:Fire("Disable") end
            if ent:GetName() == "map_push_green" then ent:Fire("Disable") end
            if ent:GetName() == "map_push_yellow" then ent:Fire("Disable") end
        end
    end)

    timer.Simple(delay, function()
        -- PrintMessage(HUD_PRINTTALK, "checking for win")
        if GetConVar("sts_sudden_death"):GetInt() == 1 then
            timer.Create("SuddenDeath", GetConVar("sts_sudden_death_time"):GetInt(), 1, function()
                suddenDeath = true
                SendServerMessage("Sudden Death has started! Kill all enemy mobs to win!", Color(255, 255, 255), 3)
            end)
        end

        timer.Create("CheckForWin", 1, 0, function()
            local alivetimer = table.shallow_copy(alive)
            local amountalive = 0
            local name
            for _, ent in ipairs(ents.GetAll()) do
                name = ent:GetName():lower()
                if (name == "redteam" or name == "greenteam" or name == "yellowteam" or name == "blueteam") and ent:IsValid() and ent:IsNPC() and ent:Health() > 0 and alivetimer[name] ~= -1 then alivetimer[name] = alivetimer[name] + 1 end
            end

            for aliveteam, _ in pairs(alive) do
                if alivetimer[aliveteam] > 0 then
                    amountalive = amountalive + 1
                    winner = aliveteam
                end

                if suddenDeath then
                    for _, ent in ipairs(ents.GetAll()) do
                        if ent:GetName() == aliveteam and ent:IsValid() and ent:IsNPC() then
                            for i, ply in pairs(team.GetPlayers(getTeamIDFromName(winnerShorter[aliveteam]))) do
                                ent:AddEntityRelationship(ply, D_LI, 10)
                            end
                        elseif ent:IsNPC() and ent:IsValid() then
                            for i, ply in pairs(team.GetPlayers(getTeamIDFromName(winnerShorter[aliveteam]))) do
                                ent:AddEntityRelationship(ply, D_HT, 10)
                            end
                        end
                    end

                    -- teleport all players into arena
                    for i, ply in pairs(team.GetPlayers(getTeamIDFromName(winnerShorter[aliveteam]))) do
                        ply:SetHealth(100)
                        ply:Give("weapon_pistol")
                        ply:SetAmmo(1000, "Pistol")
                        ply:SetPos(nextMapSpawnLocations[getTeamNameFromID(ply:Team())][i][1])
                        ply:SetAngles(nextMapSpawnLocations[getTeamNameFromID(ply:Team())][i][2])
                    end

                    enablePlayerWallhacksGlobally()
                end

                if alivetimer[aliveteam] == 0 and amountalive > 1 then
                    SendServerMessage(formattedWinner[aliveteam] .. " Team Defeated!", winnerColor[aliveteam], 3)
                    alivetimer[aliveteam] = -1 -- do not repeat message
                    alive[aliveteam] = -1
                    if math.random(1, 50) == 1 then
                        playGlobalSound("sts_announcer/" .. winnerShorter[aliveteam] .. "_lose_funny.wav")
                    else
                        playGlobalSound("sts_announcer/" .. winnerShorter[aliveteam] .. "_lose" .. math.random(1, 2) .. ".wav")
                    end
                end
            end

            if amountalive == 1 then
                timer.Remove("CheckForWin")
                timer.Remove("SuddenDeath")
                local difference = GetConVar("sts_winner_points"):GetInt() - GetConVar("sts_loser_points"):GetInt()
                if winner == "blueteam" then
                    team.AddScore(1, 1)
                    teams[1].points = teams[1].points + difference
                elseif winner == "redteam" then
                    team.AddScore(2, 1)
                    teams[2].points = teams[2].points + difference
                elseif winner == "greenteam" then
                    team.AddScore(3, 1)
                    teams[3].points = teams[3].points + difference
                elseif winner == "yellowteam" then
                    team.AddScore(4, 1)
                    teams[4].points = teams[4].points + difference
                end

                soundTrack:Stop()
                for teamID = 1, 4 do
                    teams[teamID].points = teams[teamID].points + GetConVar("sts_loser_points"):GetInt()
                    SendPointsToTeamMembers(teamID)
                end

                SendServerMessage(formattedWinner[winner] .. " Team Wins!", winnerColor[winner], 5)
                playGlobalSound("sts_announcer/" .. winnerShorter[winner] .. "_win" .. math.random(1, 3) .. ".wav")
                endRound()
                disablePlayerWallhacksGlobally()
                disableNPCWallhacksGlobally()
            elseif amountalive == 0 then
                timer.Remove("CheckForWin")
                timer.Remove("SuddenDeath")
                soundTrack:Stop()
                for teamID = 1, 4 do
                    teams[teamID].points = teams[teamID].points + GetConVar("sts_loser_points"):GetInt()
                    SendPointsToTeamMembers(teamID)
                end

                playGlobalSound("sts_announcer/tie.wav")
                SendServerMessage("Tie!", Color(255, 255, 255), 3)
                endRound()
                disablePlayerWallhacksGlobally()
                disableNPCWallhacksGlobally()
            end
        end)
    end)
end

function endRound()
    -- PrintMessage(HUD_PRINTTALK, "Round over!")
    endTeamAssignment()
    cleanupMap(nextMap)
    nextMap = chooseNextMap()
    setNextMapScreen(getMapScreen(nextMap))
    for _, ply in ipairs(player.GetAll()) do
        ply:StripWeapons()
        teleportToTeamSpawn(ply)
    end

    startLobbySpawn()
    stopGameSpawn()
    roundReset()
    local blockers = {"waiting_bluewall", "waiting_redwall", "waiting_greenwall", "waiting_yellowwall"}
    local mobnames = {"blueteam", "redteam", "greenteam", "yellowteam"}
    for _, ent in ipairs(ents.GetAll()) do
        for _, wall in ipairs(blockers) do
            if ent:GetName() == wall then ent:Remove() end
        end

        for _, mob in ipairs(mobnames) do
            if ent:GetName():lower() == mob or ent:GetName():lower() == mob .. "notp" then ent:Remove() end
        end

        if ent:IsNPC() and ent:GetName() == "" then ent:Remove() end
    end
end

function setupMap(map)
    for _, ent in ipairs(ents.GetAll()) do
        -- if ent:GetName() == "map_push_red" then
        --     ent:Fire("Enable")
        -- end
        -- if ent:GetName() == "map_push_blue" then
        --     ent:Fire("Enable")
        -- end
        -- if ent:GetName() == "map_push_green" then
        --     ent:Fire("Enable")
        -- end
        -- if ent:GetName() == "map_push_yellow" then
        --     ent:Fire("Enable")
        -- end
        -- if map == "blue" then
        -- end
        -- if map == "yellow" then
        -- end
        -- if map == "green" then
        -- end
        -- if map == "lake" then
        -- end
        -- if map == "rail" then
        -- end
        if map == "rav" then
            if ent:GetName() == "maprav_template_car" then ent:Fire("Forcespawn") end
            if string.find(ent:GetName(), "maprav_door_") then timer.Simple(2, function() ent:Fire("Open") end) end
        end

        if map == "cit" then
            if string.find(ent:GetName(), "mapcit_ball_") then ent:Fire("Enable") end
            if string.find(ent:GetName(), "mapcit_ballbeam") then ent:Fire("Toggle") end
        end
        -- if map == "square" then
        -- end
    end

    if map == "rail" then
        -- PrintMessage(HUD_PRINTTALK, "train spawn")
        timer.Create("trainSpawn", 5, 0, function()
            local directions = {"ns", "sn", "ew", "we"}
            local direction = directions[math.random(#directions)]
            if math.random(1, 4) == 1 then
                -- PrintMessage(HUD_PRINTTALK, "train spawn" .. direction)
                -- PrintMessage(HUD_PRINTTALK, "maprail_rail_" .. direction .. "_template")
                for _, ent in ipairs(ents.GetAll()) do
                    if ent:GetName():lower() == "maprail_rail_" .. direction .. "_template" then
                        -- PrintMessage(HUD_PRINTTALK, "train spawn" .. direction .. " found")
                        ent:Fire("ForceSpawn")
                    end
                end
            end
        end)
    end
end

function cleanupMap(map)
    for _, ent in ipairs(ents.GetAll()) do
        -- if ent:GetName() == "map_push_red" then
        --     ent:Fire("Disable")
        -- end
        -- if ent:GetName() == "map_push_blue" then
        --     ent:Fire("Disable")
        -- end
        -- if ent:GetName() == "map_push_green" then
        --     ent:Fire("Disable")
        -- end
        -- if ent:GetName() == "map_push_yellow" then
        --     ent:Fire("Disable")
        -- end
        -- if map == "blue" then
        -- end
        -- if map == "yellow" then
        -- end
        -- if map == "green" then
        -- end
        -- if map == "lake" then
        -- end
        -- if map == "rail" then
        -- end
        if map == "rav" then
            if string.find(ent:GetName(), "maprav_car_") then ent:Remove() end
            if string.find(ent:GetName(), "maprav_door_") then ent:Fire("Close") end
        end

        if map == "cit" then
            if string.find(ent:GetName(), "mapcit_ball_") then ent:Fire("Disable") end
            if string.find(ent:GetName(), "mapcit_ballbeam") then ent:Fire("Toggle") end
        end
        -- if map == "square" then
        -- end
    end

    if map == "rail" then timer.Remove("trainSpawn") end
end

function doBonusRound()
    getBonusRoundBeginFunc()()
    nextBR = chooseBonusRound()
end

function getPlayingTeams()
    local ids = {}
    for i = 1, 4 do
        if #team.GetPlayers(i) > 0 then table.insert(ids, i) end
    end
    -- return {1,2} -- for testing
    return ids
end

function gameOver()
    local winnertpcoords
    local losertpcoords
    local winningTeam
    local highestscore = 0
    stopLobbySpawn()
    stopGameSpawn()
    playGlobalSound("sts_music/end_win.wav")
    for _, teamID in ipairs(getPlayingTeams()) do
        if team.GetScore(teamID) > highestscore then
            winningTeam = teamID
            highestscore = team.GetScore(teamID)
        end
    end

    for _, ent in ipairs(ents.GetAll()) do
        if ent:GetName() == "end_winnertp" then
            winnertpcoords = ent:GetPos()
        elseif ent:GetName() == "end_losertp" then
            losertpcoords = ent:GetPos()
        elseif ent:GetName() == "end_guard_template" then
            ent:Fire("ForceSpawn")
        end
    end

    local delay = 0.5 -- seconds
    local timeElapsed = 0
    for _, ply in ipairs(player.GetAll()) do
        -- Increase delay for each player
        timer.Simple(timeElapsed, function()
            if not IsValid(ply) then -- Check if the player is still valid
                return
            end

            if ply:Team() == winningTeam then
                ply:SetPos(winnertpcoords)
            else
                ply:SetPos(losertpcoords)
                ply:SetWalkSpeed(75)
                ply:SetRunSpeed(125)
            end
        end)

        timeElapsed = timeElapsed + delay
    end

    hook.Add("PlayerSpawn", "EndSpawn", function(ply)
        if ply:Team() == winningTeam then
            ply:SetPos(winnertpcoords)
        else
            ply:SetPos(losertpcoords)
            -- this is necessary because the player spawn hook is called before the player is actually spawned
            timer.Simple(0.1, function()
                ply:SetWalkSpeed(75)
                ply:SetRunSpeed(125)
                ply:SetNoCollideWithTeammates(true)
            end)
        end
    end)

    hook.Add("PlayerDeath", "RespawnLoser", function(victim, inflictor, attacker) timer.Simple(2, function() if victim:Alive() == false then victim:Spawn() end end) end)
    timer.Simple(30, function() gameReset() end)
    -- this will never actually run and is just to prevent the garbage collector from removing the sound
    timer.Simple(40, function() endWinSound:Stop() end)
end
