batteryPositions = {
    [1] = false,
    [2] = false,
    [3] = false,
    [4] = false,
    [5] = false,
    [6] = false,
    [7] = false
}

function deathmatchKill(victim, inflictor, attacker)
    if attacker == victim then
        attacker:PrintMessage(HUD_PRINTTALK, "Quit killing yourself")
    elseif attacker:IsPlayer() then
        local teamnum = attacker:Team()
        if teamnum < 1 or teamnum > 4 then return 0 end
        if teamnum == victim:Team() then
            attacker:PrintMessage(HUD_PRINTTALK, "Quit Team Killing")
        else
            if teamnum == 1 then
                PrintMessage(HUD_PRINTTALK, "Blue Team Gained a Point!")
            elseif teamnum == 2 then
                PrintMessage(HUD_PRINTTALK, "Red Team Gained a Point!")
            elseif teamnum == 3 then
                PrintMessage(HUD_PRINTTALK, "Green Team Gained a Point!")
            elseif teamnum == 4 then
                PrintMessage(HUD_PRINTTALK, "Yellow Team Gained a Point!")
            end

            teams[teamnum].points = teams[teamnum].points + GetConVar("sts_deathmatch_points"):GetInt()
            SendPointsToTeamMembers(teamnum)
            return teamnum
        end
    end
    return 0
end

function beginSurvival()
    bonusSurvivors = {}
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() >= 1 and ply:Team() <= 4 then bonusSurvivors[ply:SteamID()] = true end
    end

    hook.Add("PostPlayerDeath", "SurvivalDeath", survivalDeath)
end

function survivalDeath(ply)
    bonusSurvivors[ply:SteamID()] = false
end

function endSurvival()
    for _, ply in ipairs(player.GetAll()) do
        if bonusSurvivors[ply:SteamID()] == true and teams[ply:Team()] and teams[ply:Team()].points then teams[ply:Team()].points = teams[ply:Team()].points + GetConVar("sts_survival_points"):GetInt() end
    end

    for teamIndex = 1, 4 do
        SendPointsToTeamMembers(teamIndex)
    end

    bonusSurvivors = {}
    hook.Remove("PostPlayerDeath", "SurvivalDeath")
end

-- called in game by luarunner
function awardCTF(teamID)
    if teamID == 1 then
        PrintMessage(HUD_PRINTTALK, "Blue Team Captured the Flag!")
    elseif teamID == 2 then
        PrintMessage(HUD_PRINTTALK, "Red Team Captured the Flag!")
    elseif teamID == 3 then
        PrintMessage(HUD_PRINTTALK, "Green Team Captured the Flag!")
    elseif teamID == 4 then
        PrintMessage(HUD_PRINTTALK, "Yellow Team Captured the Flag!")
    end

    teams[teamID].points = teams[teamID].points + GetConVar("sts_ctf_points"):GetInt()
    SendPointsToTeamMembers(teamID)
end

function awardBattery(teamID)
    if teamID == 1 then
        PrintMessage(HUD_PRINTTALK, "Blue Team Gained a Battery!")
    elseif teamID == 2 then
        PrintMessage(HUD_PRINTTALK, "Red Team Gained a Battery!")
    elseif teamID == 3 then
        PrintMessage(HUD_PRINTTALK, "Green Team Gained a Battery!")
    elseif teamID == 4 then
        PrintMessage(HUD_PRINTTALK, "Yellow Team Gained a Battery!")
    end

    teams[teamID].points = teams[teamID].points + GetConVar("sts_battery_points"):GetInt()
    SendPointsToTeamMembers(teamID)
end

function batteryTouching(id)
    batteryPositions[id] = true
end

function batteryLeaving(id)
    batteryPositions[id] = false
end

hook.Add("PlayerDeath", "Deathmatch Add Points", deathmatchKill) -- this can be on forever cause if someone figures out a way to kill outside of a bonus round thats funny asf
function getBonusRoundBeginFunc()
    local lookupTable = {
        ["waiting_lobby_mapleverb_lake"] = beginElMatador,
        ["waiting_lobby_mapleverb_blue"] = beginSpaceSMGs,
        ["waiting_lobby_mapleverb_green"] = beginCrabRave,
        ["waiting_lobby_mapleverb_boomstick"] = beginBoomstick,
        ["waiting_lobby_mapleverb_ctf"] = beginCTF,
        ["waiting_lobby_mapleverb_battery"] = beginBattery,
        ["waiting_lobby_mapleverb_ravsurv"] = beginRavenholm,
        ["waiting_lobby_mapleverb_rav"] = beginHl2dm,
        ["waiting_lobby_mapleverb_cit"] = beginDodgeball,
        ["waiting_lobby_mapleverb_square"] = beginLookUp
    }

    local br = lookupTable[nextBR]
    return br
end

function getBonusRoundEndFunc()
    local lookupTable = {
        ["waiting_lobby_mapleverb_lake"] = endElMatador,
        ["waiting_lobby_mapleverb_blue"] = endSpaceSMGs,
        ["waiting_lobby_mapleverb_green"] = endCrabRave,
        ["waiting_lobby_mapleverb_boomstick"] = endBoomstick,
        ["waiting_lobby_mapleverb_ctf"] = endCTF,
        ["waiting_lobby_mapleverb_battery"] = endBattery,
        ["waiting_lobby_mapleverb_ravsurv"] = endRavenholm,
        ["waiting_lobby_mapleverb_rav"] = endHl2dm,
        ["waiting_lobby_mapleverb_cit"] = endDodgeball,
        ["waiting_lobby_mapleverb_square"] = endLookUp
    }

    local br = lookupTable[nextBR]
    return br
end

function elMatadorTeleport(ply)
    local chosen = math.random(1, 4)
    for _, ent in ipairs(ents.FindByClass("info_teleport_destination")) do
        if ent:GetName() == ("maplake" .. "_player_" .. getTeamNameFromID(ply:Team()) .. "tpdest" .. tostring(chosen)) then
            ply:SetPos(ent:GetPos())
            ply:SetEyeAngles(ent:GetAngles())
            -- print("map" .. nextMap .. "_player_" .. getTeamNameFromID(ply:Team()) .. "tpdest" .. tostring(chosen))
            break
        end
    end
end

function beginElMatador()
    hook.Add("PlayerSpawn", "ElMatadorTP", elMatadorTeleport)
    stopLobbySpawn()
    beginSurvival()
    local ElMatadorSound
    local desiredTime = GetConVar("sts_survival_time"):GetInt()
    for _, ply in ipairs(player.GetAll()) do
        ply:ScreenFade(SCREENFADE.OUT, Color(0, 0, 0, 255), 1, 4)
    end

    timer.Simple(1, function()
        SendServerMessage("Bonus Round!", Color(255, 0, 255), 0)
        muteMainTrack()
    end)

    timer.Simple(3, function()
        SendServerMessage("El Matador!", Color(255, 0, 255), 2)
        ElMatadorSound = playGlobalSound("sts_music/go_together_ashija.wav") -- this has to be a global object because this is the only way i can figure out how to prevent it from stopping randomly
    end)

    -- TODO: determine the root cause and find a better solution
    timer.Simple(4, function()
        SendTimerEnd(engine.TickCount() + (desiredTime * 66))
        for _, ply in ipairs(player.GetAll()) do
            local chosen = math.random(1, 5)
            for _, ent in ipairs(ents.FindByClass("info_teleport_destination")) do
                if ent:GetName() == ("maplake" .. "_" .. getTeamNameFromID(ply:Team()) .. "spawn" .. tostring(chosen)) then
                    ply:SetPos(ent:GetPos())
                    ply:SetHealth(20)
                    ply:SetEyeAngles(ent:GetAngles())
                    break
                end
            end
        end

        for _, ent in ipairs(ents.FindByClass("point_template")) do
            if ent:GetName() == "maplake_bonus_guardtemp" then ent:Fire("ForceSpawn") end
        end

        timer.Create("MatadorSpawn", desiredTime / 4, 3, function()
            for _, ent in ipairs(ents.FindByClass("point_template")) do
                if ent:GetName() == "maplake_bonus_guardtemp" then ent:Fire("ForceSpawn") end
            end
        end)
    end)

    timer.Create("checkIfAllDead", 1, 0, function()
        local allDead = true
        for _, ply in ipairs(player.GetAll()) do
            if bonusSurvivors[ply:SteamID()] == true then
                allDead = false
                break
            end
        end

        if allDead == true then
            endElMatador()
            ElMatadorSound:Stop()
            ElMatadorSound = nil -- clear from memory
            timer.Remove("checkIfAllDead")
            timer.Remove("endThing")
            SendTimerEnd(0)
        end
    end)

    timer.Create("endThing", desiredTime + 4, 1, function()
        endElMatador()
        ElMatadorSound:Stop()
        ElMatadorSound = nil -- clear from memory
    end)
end

function endElMatador()
    hook.Remove("PlayerSpawn", "ElMatadorTP")
    timer.Remove("checkIfAllDead")
    SendTimerEnd(0)
    startLobbySpawn()
    for _, ent in ipairs(ents.GetAll()) do
        if ent:GetClass() == "npc_antlionguard" then ent:Remove() end
    end

    unmuteMainTrack()
    endSurvival()
    for _, ply in ipairs(player.GetAll()) do
        teleportToTeamSpawn(ply)
    end

    timer.Remove("MatadorSpawn")
end

function SpaceSMGsTeleport(ply)
    -- this is a dm minigame which requires random tps around the map
    local chosen = math.random(1, 5)
    for _, ent in ipairs(ents.FindByClass("info_teleport_destination")) do
        if ent:GetName() == ("mapblue" .. "_" .. getTeamNameFromID(ply:Team()) .. "spawn" .. tostring(chosen)) then
            ply:SetPos(ent:GetPos())
            ply:SetEyeAngles(ent:GetAngles())
            break
        end
    end
end

function beginSpaceSMGs()
    hook.Add("PlayerSpawn", "SpaceSMGTP", SpaceSMGsTeleport)
    stopLobbySpawn()
    local desiredTime = GetConVar("sts_deathmatch_time"):GetInt()
    local SpaceSMGsSound
    for _, ply in ipairs(player.GetAll()) do
        ply:ScreenFade(SCREENFADE.OUT, Color(0, 0, 0, 255), 1, 4)
    end

    timer.Simple(1, function()
        SendServerMessage("Bonus Round!", Color(255, 0, 255), 0)
        muteMainTrack()
    end)

    timer.Simple(3, function()
        SendServerMessage("Space SMGs!", Color(255, 0, 255), 2)
        SpaceSMGsSound = playGlobalSound("sts_music/triage_at_dawn_remix.wav") -- this has to be a global object because this is the only way i can figure out how to prevent it from stopping randomly
    end)

    -- TODO: determine the root cause and find a better solution
    hook.Remove("PlayerLoadout", "Default")
    hook.Add("PlayerLoadout", "SpaceSMG", function(ply)
        ply:Give("weapon_smg1")
        ply:SetAmmo(1000, "SMG1")
        ply:SetAmmo(1000, "SMG1_Grenade")
        ply:Give("weapon_357")
        ply:SetAmmo(1000, "357")
        ply:Give("weapon_crowbar")
        return true
    end)

    timer.Simple(4, function()
        updateGravityToClients(0.3)
        SendTimerEnd(engine.TickCount() + (desiredTime * 66))
        for _, ply in ipairs(player.GetAll()) do
            local chosen = math.random(1, 5)
            for _, ent in ipairs(ents.FindByClass("info_teleport_destination")) do
                if ent:GetName() == ("mapblue" .. "_" .. getTeamNameFromID(ply:Team()) .. "spawn" .. tostring(chosen)) then
                    ply:SetPos(ent:GetPos())
                    ply:SetEyeAngles(ent:GetAngles())
                    ply:Give("weapon_smg1")
                    ply:SetAmmo(1000, "SMG1")
                    ply:SetAmmo(1000, "SMG1_Grenade")
                    ply:Give("weapon_357")
                    ply:SetAmmo(1000, "357")
                    ply:Give("weapon_crowbar")
                    break
                end
            end
        end
    end)

    timer.Simple(desiredTime + 4, function()
        endSpaceSMGs()
        SpaceSMGsSound:Stop()
        SpaceSMGsSound = nil -- clear from memory
    end)
end

function endSpaceSMGs()
    hook.Remove("PlayerSpawn", "SpaceSMGTP")
    hook.Remove("PlayerLoadout", "SpaceSMG")
    hook.Add("PlayerLoadout", "Default", function(ply) return true end)
    startLobbySpawn()
    unmuteMainTrack()
    for _, ply in ipairs(player.GetAll()) do
        ply:StripWeapons()
        teleportToTeamSpawn(ply)
    end

    updateGravityToClients(1)
end

function CTFTeleport(ply)
    -- this is a dm minigame which requires random tps around the map
    local chosen = math.random(1, 4)
    for _, ent in ipairs(ents.FindByClass("info_teleport_destination")) do
        if ent:GetName() == ("mapctf" .. "_" .. getTeamNameFromID(ply:Team()) .. "spawndest" .. tostring(chosen)) then
            ply:SetPos(ent:GetPos())
            ply:SetEyeAngles(ent:GetAngles())
            break
        end
    end
end

function beginCTF()
    hook.Add("PlayerSpawn", "CTFTP", CTFTeleport)
    stopLobbySpawn()
    local desiredTime = GetConVar("sts_deathmatch_time"):GetInt()
    local CTFSound
    for _, ply in ipairs(player.GetAll()) do
        ply:ScreenFade(SCREENFADE.OUT, Color(0, 0, 0, 255), 1, 4)
    end

    timer.Simple(1, function()
        SendServerMessage("Bonus Round!", Color(255, 0, 255), 0)
        muteMainTrack()
    end)

    timer.Simple(3, function()
        SendServerMessage("Capture the Flag!", Color(255, 0, 255), 2)
        CTFSound = playGlobalSound("sts_music/something_secret_steers.wav") -- this has to be a global object because this is the only way i can figure out how to prevent it from stopping randomly
    end)

    hook.Remove("PlayerLoadout", "Default")
    hook.Add("PlayerLoadout", "CTF", function(ply)
        ply:Give("weapon_pistol")
        ply:SetAmmo(1000, "Pistol")
        ply:Give("weapon_slam")
        ply:SetAmmo(1000, "slam")
        ply:Give("weapon_crowbar")
        ply:Give("weapon_frag")
        ply:Give("weapon_crossbow")
        ply:SetAmmo(1000, "XBowBolt")
        return true
    end)

    timer.Simple(4, function()
        SendTimerEnd(engine.TickCount() + (desiredTime * 66))
        for _, ent in ipairs(ents.GetAll()) do
            if ent:GetName() == "mapctf_flag_template" then ent:Fire("ForceSpawn") end
        end

        for _, ply in ipairs(player.GetAll()) do
            local chosen = math.random(1, 4)
            for _, ent in ipairs(ents.FindByClass("info_teleport_destination")) do
                if ent:GetName() == ("mapctf" .. "_" .. getTeamNameFromID(ply:Team()) .. "spawndest" .. tostring(chosen)) then
                    ply:SetPos(ent:GetPos())
                    ply:SetEyeAngles(ent:GetAngles())
                    ply:Give("weapon_pistol")
                    ply:SetAmmo(1000, "Pistol")
                    ply:Give("weapon_slam")
                    ply:SetAmmo(1000, "slam")
                    ply:Give("weapon_crowbar")
                    ply:Give("weapon_frag")
                    ply:SetAmmo(1000, "Grenade")
                    ply:Give("weapon_crossbow")
                    ply:SetAmmo(1000, "XBowBolt")
                    break
                end
            end
        end
    end)

    timer.Simple(desiredTime + 4, function()
        endCTF()
        CTFSound:Stop()
        CTFSound = nil -- clear from memory
    end)
end

function endCTF()
    hook.Remove("PlayerSpawn", "CTFTP")
    hook.Remove("PlayerLoadout", "CTF")
    hook.Add("PlayerLoadout", "Default", function(ply) return true end)
    startLobbySpawn()
    unmuteMainTrack()
    for _, ply in ipairs(player.GetAll()) do
        ply:StripWeapons()
        teleportToTeamSpawn(ply)
    end

    for _, ent in ipairs(ents.GetAll()) do
        if string.sub(ent:GetName(), 0, 4) == "flag" then ent:Remove() end
    end
end

function BatteryTeleport(ply)
    -- this is a dm minigame which requires random tps around the map
    local chosen = math.random(1, 4)
    for _, ent in ipairs(ents.FindByClass("info_teleport_destination")) do
        if ent:GetName() == ("mapctf" .. "_" .. getTeamNameFromID(ply:Team()) .. "spawndest" .. tostring(chosen)) then
            ply:SetPos(ent:GetPos())
            ply:SetEyeAngles(ent:GetAngles())
            break
        end
    end
end

function beginBattery()
    hook.Add("PlayerSpawn", "BatteryTP", BatteryTeleport)
    stopLobbySpawn()
    local desiredTime = GetConVar("sts_deathmatch_time"):GetInt()
    local BatterySound
    for _, ply in ipairs(player.GetAll()) do
        ply:ScreenFade(SCREENFADE.OUT, Color(0, 0, 0, 255), 1, 4)
    end

    timer.Simple(1, function()
        SendServerMessage("Bonus Round!", Color(255, 0, 255), 0)
        muteMainTrack()
    end)

    timer.Simple(3, function()
        SendServerMessage("Batteries!", Color(255, 0, 255), 2)
        BatterySound = playGlobalSound("sts_music/something_secret_steers.wav") -- this has to be a global object because this is the only way i can figure out how to prevent it from stopping randomly
    end)

    hook.Remove("PlayerLoadout", "Default")
    hook.Add("PlayerLoadout", "Battery", function(ply)
        ply:Give("weapon_pistol")
        ply:SetAmmo(1000, "Pistol")
        ply:Give("weapon_slam")
        ply:SetAmmo(1000, "slam")
        ply:Give("weapon_crowbar")
        ply:Give("weapon_physcannon")
        ply:Give("weapon_frag")
        ply:Give("weapon_crossbow")
        ply:SetAmmo(1000, "XBowBolt")
        return true
    end)

    timer.Simple(4, function()
        SendTimerEnd(engine.TickCount() + (desiredTime * 66))
        for _, ply in ipairs(player.GetAll()) do
            local chosen = math.random(1, 4)
            for _, ent in ipairs(ents.FindByClass("info_teleport_destination")) do
                if ent:GetName() == ("mapctf" .. "_" .. getTeamNameFromID(ply:Team()) .. "spawndest" .. tostring(chosen)) then
                    ply:SetPos(ent:GetPos())
                    ply:SetEyeAngles(ent:GetAngles())
                    ply:Give("weapon_pistol")
                    ply:SetAmmo(1000, "Pistol")
                    ply:Give("weapon_slam")
                    ply:SetAmmo(1000, "slam")
                    ply:Give("weapon_crowbar")
                    ply:Give("weapon_physcannon")
                    ply:Give("weapon_frag")
                    ply:Give("weapon_crossbow")
                    ply:SetAmmo(1000, "XBowBolt")
                    break
                end
            end
        end

        timer.Create("batterySpawning", 10, 0, function()
            local possibleBatterySpawns = {}
            for i, bat in ipairs(batteryPositions) do
                if bat == false then table.insert(possibleBatterySpawns, i) end
            end

            if #possibleBatterySpawns ~= 0 then
                local chosenSpawn = possibleBatterySpawns[math.random(#possibleBatterySpawns)]
                for _, ent in ipairs(ents.GetAll()) do
                    if ent:GetName() == "mapctf_battery_tp" .. tostring(chosenSpawn) then ent:Fire("ForceSpawn") end
                end
            end
        end)
    end)

    timer.Simple(desiredTime + 4, function()
        endBattery()
        BatterySound:Stop()
        BatterySound = nil -- clear from memory
    end)
end

function endBattery()
    hook.Remove("PlayerSpawn", "BatteryTP")
    hook.Remove("PlayerLoadout", "Battery")
    hook.Add("PlayerLoadout", "Default", function(ply) return true end)
    timer.Remove("batterySpawning")
    startLobbySpawn()
    unmuteMainTrack()
    for _, ply in ipairs(player.GetAll()) do
        ply:StripWeapons()
        teleportToTeamSpawn(ply)
    end

    for _, ent in ipairs(ents.GetAll()) do
        if ent:GetName() == "battery" then ent:Fire("Kill") end
    end
end

function crabRaveTeleport(ply)
    -- survival minigame, players need to be teleported to a safe location
    local chosen = math.random(1, 4)
    for _, ent in ipairs(ents.FindByClass("info_teleport_destination")) do
        if ent:GetName() == ("mapgreen" .. "_player_" .. getTeamNameFromID(ply:Team()) .. "tpdest" .. tostring(chosen)) then
            ply:SetPos(ent:GetPos())
            ply:SetEyeAngles(ent:GetAngles())
            break
        end
    end
end

function beginCrabRave()
    hook.Add("PlayerSpawn", "CrabRaveTP", crabRaveTeleport)
    local desiredTime = GetConVar("sts_survival_time"):GetInt()
    beginSurvival()
    stopLobbySpawn()
    local CrabRaveSound
    for _, ply in ipairs(player.GetAll()) do
        ply:ScreenFade(SCREENFADE.OUT, Color(0, 0, 0, 255), 1, 4)
    end

    timer.Simple(1, function()
        SendServerMessage("Bonus Round!", Color(255, 0, 255), 0)
        muteMainTrack()
    end)

    timer.Simple(3, function()
        SendServerMessage("Crab Rave!", Color(255, 0, 255), 2)
        CrabRaveSound = playGlobalSound("sts_music/go_together_ashija.wav") -- this has to be a global object because this is the only way i can figure out how to prevent it from stopping randomly
    end)

    timer.Simple(4, function()
        SendTimerEnd(engine.TickCount() + (desiredTime * 66))
        for _, ply in ipairs(player.GetAll()) do
            local chosen = math.random(1, 5)
            for _, ent in ipairs(ents.FindByClass("info_teleport_destination")) do
                if ent:GetName() == ("mapgreen" .. "_" .. getTeamNameFromID(ply:Team()) .. "spawn" .. tostring(chosen)) then
                    ply:SetPos(ent:GetPos())
                    ply:SetHealth(1)
                    ply:SetEyeAngles(ent:GetAngles())
                    break
                end
            end
        end

        for _, ent in ipairs(ents.FindByClass("point_template")) do
            if ent:GetName() == "mapgreen_bonus_crabtemp2" then ent:Fire("ForceSpawn") end
        end

        timer.Create("HeadCrabSpawn", desiredTime / 8, 7, function()
            for _, ent in ipairs(ents.FindByClass("point_template")) do
                if ent:GetName() == "mapgreen_bonus_crabtemp2" then ent:Fire("ForceSpawn") end
            end
        end)
    end)

    timer.Create("checkIfAllDead", 1, 0, function()
        local allDead = true
        for _, ply in ipairs(player.GetAll()) do
            if bonusSurvivors[ply:SteamID()] == true then
                allDead = false
                break
            end
        end

        if allDead == true then
            endCrabRave()
            CrabRaveSound:Stop()
            CrabRaveSound = nil -- clear from memory
            timer.Remove("checkIfAllDead")
            timer.Remove("endThing")
            timer.Remove("HeadCrabSpawn")
            SendTimerEnd(0)
        end
    end)

    timer.Create("endThing", desiredTime + 4, 1, function()
        endCrabRave()
        CrabRaveSound:Stop()
        CrabRaveSound = nil -- clear from memory
    end)
end

function endCrabRave()
    hook.Remove("PlayerSpawn", "CrabRaveTP")
    startLobbySpawn()
    timer.Remove("checkIfAllDead")
    SendTimerEnd(0)
    for _, ent in ipairs(ents.GetAll()) do
        if ent:GetClass() == "npc_headcrab_fast" then ent:Remove() end
    end

    endSurvival()
    unmuteMainTrack()
    for _, ply in ipairs(player.GetAll()) do
        teleportToTeamSpawn(ply)
    end
end

function boomstickTeleport(ply)
    -- deathmatch
    local chosen = math.random(1, 5)
    for _, ent in ipairs(ents.FindByClass("info_teleport_destination")) do
        if ent:GetName() == ("maprail" .. "_" .. getTeamNameFromID(ply:Team()) .. "spawn" .. tostring(chosen)) then
            ply:SetPos(ent:GetPos())
            ply:SetEyeAngles(ent:GetAngles())
            break
        end
    end
end

function beginBoomstick()
    hook.Add("PlayerSpawn", "BoomstickTP", boomstickTeleport)
    stopLobbySpawn()
    local desiredTime = GetConVar("sts_deathmatch_time"):GetInt()
    local BoomstickSound
    for _, ply in ipairs(player.GetAll()) do
        ply:ScreenFade(SCREENFADE.OUT, Color(0, 0, 0, 255), 1, 4)
    end

    timer.Simple(1, function()
        SendServerMessage("Bonus Round!", Color(255, 0, 255), 0)
        muteMainTrack()
    end)

    timer.Simple(3, function()
        SendServerMessage("Boomsticks!", Color(255, 0, 255), 2)
        BoomstickSound = playGlobalSound("sts_music/funky_beat.wav") -- this has to be a global object because this is the only way i can figure out how to prevent it from stopping randomly
    end)

    hook.Remove("PlayerLoadout", "Default")
    hook.Add("PlayerLoadout", "Boomstick", function(ply)
        ply:Give("weapon_shotgun")
        ply:SetAmmo(1000, "Buckshot")
        ply:Give("weapon_crowbar")
        ply:SetHealth(50)
        return true
    end)

    timer.Simple(4, function()
        SendTimerEnd(engine.TickCount() + (desiredTime * 66))
        for _, ply in ipairs(player.GetAll()) do
            local chosen = math.random(1, 5)
            for _, ent in ipairs(ents.FindByClass("info_teleport_destination")) do
                if ent:GetName() == ("maprail" .. "_" .. getTeamNameFromID(ply:Team()) .. "spawn" .. tostring(chosen)) then
                    ply:SetPos(ent:GetPos())
                    ply:SetEyeAngles(ent:GetAngles())
                    ply:Give("weapon_shotgun")
                    ply:SetAmmo(1000, "Buckshot")
                    ply:Give("weapon_crowbar")
                    ply:SetHealth(50)
                    break
                end
            end
        end
    end)

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

    timer.Simple(desiredTime + 4, function()
        endBoomstick()
        BoomstickSound:Stop()
        BoomstickSound = nil -- clear from memory
    end)
end

function endBoomstick()
    hook.Remove("PlayerSpawn", "BoomstickTP")
    hook.Remove("PlayerLoadout", "Boomstick")
    hook.Add("PlayerLoadout", "Default", function(ply) return true end)
    unmuteMainTrack()
    startLobbySpawn()
    for _, ply in ipairs(player.GetAll()) do
        ply:StripWeapons()
        teleportToTeamSpawn(ply)
    end

    timer.Remove("trainSpawn")
end

function ravenholmTeleport(ply)
    -- survival
    local chosen = math.random(1, 4)
    for _, ent in ipairs(ents.FindByClass("info_teleport_destination")) do
        if ent:GetName() == ("maprav" .. "_player_" .. getTeamNameFromID(ply:Team()) .. "tpdest" .. tostring(chosen)) then
            ply:SetPos(ent:GetPos())
            ply:SetEyeAngles(ent:GetAngles())
            break
        end
    end
end

function beginRavenholm()
    hook.Add("PlayerSpawn", "RavenholmTP", ravenholmTeleport)
    local desiredTime = GetConVar("sts_survival_time"):GetInt()
    beginSurvival()
    stopLobbySpawn()
    local RavenholmSound
    for _, ply in ipairs(player.GetAll()) do
        ply:ScreenFade(SCREENFADE.OUT, Color(0, 0, 0, 255), 1, 4)
    end

    timer.Simple(1, function()
        SendServerMessage("Bonus Round!", Color(255, 0, 255), 0)
        muteMainTrack()
    end)

    timer.Simple(3, function()
        SendServerMessage("We went to Ravenholm!", Color(255, 0, 255), 2)
        RavenholmSound = playGlobalSound("sts_music/HNG3r.wav") -- this has to be a global object because this is the only way i can figure out how to prevent it from stopping randomly
    end)

    timer.Simple(4, function()
        SendTimerEnd(engine.TickCount() + (desiredTime * 66))
        for _, ent in ipairs(ents.GetAll()) do
            if ent:GetName() == "maprav_template_car" then ent:Fire("Forcespawn") end
            if string.find(ent:GetName(), "maprav_door_") then timer.Simple(2, function() ent:Fire("Open") end) end
        end

        for _, ply in ipairs(player.GetAll()) do
            ply:SetHealth(1)
            local chosen = math.random(1, 5)
            for _, ent in ipairs(ents.FindByClass("info_teleport_destination")) do
                if ent:GetName() == ("maprav" .. "_" .. getTeamNameFromID(ply:Team()) .. "spawn" .. tostring(chosen)) then
                    ply:SetPos(ent:GetPos())
                    ply:SetEyeAngles(ent:GetAngles())
                    break
                end
            end
        end

        for _, ent in ipairs(ents.FindByClass("point_template")) do
            for j = 1, 4 do
                if ent:GetName() == ("maprav_bonus_temp_zombie" .. tostring(j)) then ent:Fire("ForceSpawn") end
            end
        end

        timer.Create("ZombieSpawn", desiredTime / 5, 4, function()
            for _, ent in ipairs(ents.FindByClass("point_template")) do
                for j = 1, 4 do
                    if ent:GetName() == ("maprav_bonus_temp_zombie" .. tostring(j)) then ent:Fire("ForceSpawn") end
                end
            end
        end)
    end)

    timer.Create("checkIfAllDead", 1, 0, function()
        local allDead = true
        for _, ply in ipairs(player.GetAll()) do
            if bonusSurvivors[ply:SteamID()] == true then
                allDead = false
                break
            end
        end

        if allDead == true then
            endRavenholm()
            RavenholmSound:Stop()
            RavenholmSound = nil -- clear from memory
            timer.Remove("checkIfAllDead")
            timer.Remove("endThing")
            timer.Remove("ZombieSpawn")
            SendTimerEnd(0)
        end
    end)

    timer.Create("endThing", desiredTime + 4, 1, function()
        endRavenholm()
        RavenholmSound:Stop()
        RavenholmSound = nil -- clear from memory
    end)
end

function endRavenholm()
    hook.Remove("PlayerSpawn", "RavenholmTP")
    startLobbySpawn()
    timer.Remove("checkIfAllDead")
    for _, ent in ipairs(ents.GetAll()) do
        if ent:GetClass() == "npc_fastzombie" then ent:Remove() end
        if ent:GetClass() == "npc_headcrab_fast" then ent:Remove() end
        if string.find(ent:GetName(), "maprav_car_") then ent:Remove() end
        if string.find(ent:GetName(), "maprav_door_") then ent:Fire("Close") end
    end

    unmuteMainTrack()
    for _, ply in ipairs(player.GetAll()) do
        teleportToTeamSpawn(ply)
    end

    endSurvival()
    timer.Remove("ZombieSpawn")
end

function hl2dmTeleport(ply)
    -- deathmatch
    local chosen = math.random(1, 5)
    for _, ent in ipairs(ents.FindByClass("info_teleport_destination")) do
        if ent:GetName() == ("maprav" .. "_" .. getTeamNameFromID(ply:Team()) .. "spawn" .. tostring(chosen)) then
            ply:SetPos(ent:GetPos())
            ply:SetEyeAngles(ent:GetAngles())
            break
        end
    end
end

function beginHl2dm()
    hook.Add("PlayerSpawn", "HL2TP", hl2dmTeleport)
    stopLobbySpawn()
    local desiredTime = GetConVar("sts_deathmatch_time"):GetInt()
    local HL2DMSound
    for _, ply in ipairs(player.GetAll()) do
        ply:ScreenFade(SCREENFADE.OUT, Color(0, 0, 0, 255), 1, 4)
    end

    timer.Simple(1, function()
        SendServerMessage("Bonus Round!", Color(255, 0, 255), 0)
        muteMainTrack()
    end)

    timer.Simple(3, function()
        SendServerMessage("Half-Life 2 Deathmatch!", Color(255, 0, 255), 2)
        HL2DMSound = playGlobalSound("sts_music/funky_beat.wav") -- this has to be a global object because this is the only way i can figure out how to prevent it from stopping randomly
    end)

    hook.Remove("PlayerLoadout", "Default")
    hook.Add("PlayerLoadout", "HL2DM", function(ply)
        ply:Give("weapon_physcannon")
        ply:Give("weapon_crowbar")
        ply:SetHealth(50)
        return true
    end)

    timer.Simple(4, function()
        for _, ent in ipairs(ents.GetAll()) do
            if ent:GetName() == "maprav_bonus_timer" then ent:Fire("Enable") end
            if ent:GetName() == "maprav_template_car" then ent:Fire("Forcespawn") end
            if string.find(ent:GetName(), "maprav_door_") then timer.Simple(2, function() ent:Fire("Open") end) end
        end

        SendTimerEnd(engine.TickCount() + (desiredTime * 66))
        for _, ply in ipairs(player.GetAll()) do
            local chosen = math.random(1, 5)
            for _, ent in ipairs(ents.FindByClass("info_teleport_destination")) do
                if ent:GetName() == ("maprav" .. "_" .. getTeamNameFromID(ply:Team()) .. "spawn" .. tostring(chosen)) then
                    ply:SetPos(ent:GetPos())
                    ply:SetEyeAngles(ent:GetAngles())
                    ply:Give("weapon_physcannon")
                    ply:Give("weapon_crowbar")
                    ply:SetHealth(50)
                    break
                end
            end
        end
    end)

    timer.Simple(desiredTime + 4, function()
        endHl2dm()
        HL2DMSound:Stop()
        HL2DMSound = nil -- clear from memory
    end)
end

function endHl2dm()
    hook.Remove("PlayerSpawn", "HL2TP")
    hook.Remove("PlayerLoadout", "HL2DM")
    hook.Add("PlayerLoadout", "Default", function(ply) return true end)
    unmuteMainTrack()
    startLobbySpawn()
    for _, ply in ipairs(player.GetAll()) do
        ply:StripWeapons()
        teleportToTeamSpawn(ply)
    end

    for _, ent in ipairs(ents.GetAll()) do
        if ent:GetName() == "maprav_bonus_timer" then ent:Fire("Disable") end
        if string.find(ent:GetName(), "maprav_car_") then ent:Remove() end
        if string.find(ent:GetName(), "maprav_door_") then ent:Fire("Close") end
        if string.find(ent:GetName(), "maprav_bonus_drum_drum") then ent:Remove() end
        if string.find(ent:GetName(), "maprav_bonus_sawblade_sawblade") then ent:Remove() end
        if string.find(ent:GetName(), "maprav_bonus_brick_brick") then ent:Remove() end
    end
end

function dodgeballTeleport(ply)
    -- deathmatch
    local chosen = math.random(1, 5)
    for _, ent in ipairs(ents.FindByClass("info_teleport_destination")) do
        if ent:GetName() == ("mapcit" .. "_" .. getTeamNameFromID(ply:Team()) .. "spawn" .. tostring(chosen)) then
            ply:SetPos(ent:GetPos())
            ply:SetEyeAngles(ent:GetAngles())
            break
        end
    end
end

function beginDodgeball()
    hook.Add("PlayerSpawn", "DodgeballTP", dodgeballTeleport)
    stopLobbySpawn()
    local desiredTime = GetConVar("sts_deathmatch_time"):GetInt()
    local DodgeballSound
    for _, ply in ipairs(player.GetAll()) do
        ply:ScreenFade(SCREENFADE.OUT, Color(0, 0, 0, 255), 1, 4)
    end

    timer.Simple(1, function()
        SendServerMessage("Bonus Round!", Color(255, 0, 255), 0)
        muteMainTrack()
        for _, ent in ipairs(ents.GetAll()) do
            if string.find(ent:GetName(), "mapcit_ball_") then ent:Fire("Enable") end
            if string.find(ent:GetName(), "mapcit_ballbeam") then ent:Fire("Toggle") end
        end
    end)

    timer.Simple(3, function()
        SendServerMessage("Dodgeball!", Color(255, 0, 255), 2)
        DodgeballSound = playGlobalSound("sts_music/celestial.wav") -- this has to be a global object because this is the only way i can figure out how to prevent it from stopping randomly
    end)

    hook.Remove("PlayerLoadout", "Default")
    hook.Add("PlayerLoadout", "Dodgeball", function(ply)
        ply:Give("weapon_physcannon")
        return true
    end)

    RunConsoleCommand("physcannon_mega_enabled", "1") -- there's probably a better way to do this
    timer.Simple(4, function()
        SendTimerEnd(engine.TickCount() + (desiredTime * 66))
        for _, ply in ipairs(player.GetAll()) do
            local chosen = math.random(1, 5)
            for _, ent in ipairs(ents.FindByClass("info_teleport_destination")) do
                if ent:GetName() == ("mapcit" .. "_" .. getTeamNameFromID(ply:Team()) .. "spawn" .. tostring(chosen)) then
                    ply:SetPos(ent:GetPos())
                    ply:SetEyeAngles(ent:GetAngles())
                    ply:Give("weapon_physcannon")
                    break
                end
            end
        end
    end)

    timer.Simple(desiredTime + 4, function()
        endDodgeball()
        DodgeballSound:Stop()
        DodgeballSound = nil -- clear from memory
    end)
end

function endDodgeball()
    hook.Remove("PlayerSpawn", "DodgeballTP")
    hook.Remove("PlayerLoadout", "Dodgeball")
    hook.Add("PlayerLoadout", "Default", function(ply) return true end)
    startLobbySpawn()
    unmuteMainTrack()
    for _, ply in ipairs(player.GetAll()) do
        ply:StripWeapons()
        teleportToTeamSpawn(ply)
    end

    for _, ent in ipairs(ents.GetAll()) do
        if string.find(ent:GetName(), "mapcit_ball_") then ent:Fire("Disable") end
        if string.find(ent:GetName(), "mapcit_ballbeam") then ent:Fire("Toggle") end
    end

    RunConsoleCommand("physcannon_mega_enabled", "0")
end

function lookUpTeleport(ply)
    -- survival
    local chosen = math.random(1, 4)
    for _, ent in ipairs(ents.FindByClass("info_teleport_destination")) do
        if ent:GetName() == ("mapsquare" .. "_player_" .. getTeamNameFromID(ply:Team()) .. "tpdest" .. tostring(chosen)) then
            ply:SetPos(ent:GetPos())
            ply:SetEyeAngles(ent:GetAngles())
            ply:SetWalkSpeed(100)
            ply:SetRunSpeed(150)
            break
        end
    end
end

function beginLookUp()
    hook.Add("PlayerSpawn", "LookUpTP", lookUpTeleport)
    local desiredTime = GetConVar("sts_survival_time"):GetInt()
    beginSurvival()
    stopLobbySpawn()
    local LookUpSound
    for _, ply in ipairs(player.GetAll()) do
        ply:ScreenFade(SCREENFADE.OUT, Color(0, 0, 0, 255), 1, 4)
    end

    timer.Simple(1, function()
        SendServerMessage("Bonus Round!", Color(255, 0, 255), 0)
        muteMainTrack()
    end)

    timer.Simple(3, function()
        SendServerMessage("Look Up!", Color(255, 0, 255), 2)
        LookUpSound = playGlobalSound("sts_music/cp_violation.wav") -- this has to be a global object because this is the only way i can figure out how to prevent it from stopping randomly
    end)

    timer.Simple(4, function()
        SendTimerEnd(engine.TickCount() + (desiredTime * 66))
        local chosen = math.random(1, 5)
        for _, ply in ipairs(player.GetAll()) do
            for _, ent in ipairs(ents.FindByClass("info_teleport_destination")) do
                if ent:GetName() == ("mapsquare_" .. getTeamNameFromID(ply:Team()) .. "spawn" .. tostring(chosen)) then
                    ply:SetPos(ent:GetPos())
                    ply:SetEyeAngles(ent:GetAngles())
                    ply:SetWalkSpeed(100)
                    ply:SetRunSpeed(150)
                    ply:SetHealth(1)
                    break
                end
            end
        end

        timer.Create("lookUpSpawning", 2, 0, function()
            for _, ent in ipairs(ents.GetAll()) do
                if ent:GetName() == "mapsquare_bonus_hacktemp" then ent:Fire("ForceSpawn") end
            end
        end)
    end)

    timer.Create("checkIfAllDead", 1, 0, function()
        local allDead = true
        for _, ply in ipairs(player.GetAll()) do
            if bonusSurvivors[ply:SteamID()] == true then
                allDead = false
                break
            end
        end

        if allDead == true then
            endLookUp()
            LookUpSound:Stop()
            LookUpSound = nil -- clear from memory
            timer.Remove("checkIfAllDead")
            timer.Remove("endThing")
            SendTimerEnd(0)
        end
    end)

    timer.Create("endThing", desiredTime + 4, 1, function()
        endLookUp()
        LookUpSound:Stop()
        LookUpSound = nil -- clear from memory
    end)
end

function endLookUp()
    hook.Remove("PlayerSpawn", "LookUpTP")
    timer.Remove("checkIfAllDead")
    SendTimerEnd(0)
    unmuteMainTrack()
    endSurvival()
    startLobbySpawn()
    for _, ply in ipairs(player.GetAll()) do
        teleportToTeamSpawn(ply)
        ply:SetWalkSpeed(200)
        ply:SetRunSpeed(400)
    end

    timer.Remove("lookUpSpawning")
    for _, ent in ipairs(ents.GetAll()) do
        if ent:GetClass() == "npc_manhack" then ent:Remove() end
    end
end
