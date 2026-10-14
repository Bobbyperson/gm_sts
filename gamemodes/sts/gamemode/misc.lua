CreateConVar("sts_starting_points", "20", {FCVAR_GAMEDLL, FCVAR_REPLICATED}, "Starting points. No effect after game start.", 1, 80)
CreateConVar("sts_total_rounds", "5", {FCVAR_GAMEDLL, FCVAR_REPLICATED}, "Amount of rounds to play. No effect after game start.", 1, 24)
CreateConVar("sts_minimum_players", "2", {FCVAR_GAMEDLL, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Minimum players required before game can start.", 0, 16)
CreateConVar("sts_outfitter_support", "0", {FCVAR_GAMEDLL, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Change how team recognition is handled if using outfitter.", 0, 1)
CreateConVar("sts_forbid_dev_room", "1", {FCVAR_GAMEDLL, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Whether or not to forbid access to the secret dev room.", 0, 1)
CreateConVar("sts_disable_settings_buttons", "0", {FCVAR_GAMEDLL, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Whether or not the lobby buttons should do anything.", 0, 1)
CreateConVar("sts_force_bonus_rounds", "0", {FCVAR_GAMEDLL, FCVAR_REPLICATED, FCVAR_NOTIFY}, "1 - Force bonus rounds on\n0 - Force Nothing\n-1 - Force bonus rounds off.", -1, 1)
CreateConVar("sts_random_teams", "0", {FCVAR_GAMEDLL, FCVAR_REPLICATED, FCVAR_NOTIFY}, "0 - Allow players to choose teams\n1 - Random two teams\n2 - Random Four teams\nIf this is set to anything besides 0, the team selection will be locked. No effect after game start.", 0, 2)
CreateConVar("sts_allow_team_swapping", "0", {FCVAR_GAMEDLL, FCVAR_REPLICATED, FCVAR_NOTIFY}, "0 - Do not allow swapping teams midgame\n 1 - Allow swapping teams mid game", 0, 1)
CreateConVar("sts_deathmatch_points", "1", {FCVAR_GAMEDLL, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Determine point reward for kills in bonus rounds.", 1, 100)
CreateConVar("sts_deathmatch_time", "90", {FCVAR_GAMEDLL, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Determine time for deathmatch bonus rounds.", 20, 600)
CreateConVar("sts_survival_time", "60", {FCVAR_GAMEDLL, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Determine time for survival bonus rounds.", 20, 600)
CreateConVar("sts_survival_points", "10", {FCVAR_GAMEDLL, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Determine point reward for survival in bonus rounds.", 1, 100)
CreateConVar("sts_ctf_points", "10", {FCVAR_GAMEDLL, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Determine point reward for capturing the flag in bonus rounds.", 1, 100)
CreateConVar("sts_battery_points", "5", {FCVAR_GAMEDLL, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Determine point reward for delivering the battery in bonus rounds.", 1, 100)
CreateConVar("sts_bonus_round_interval", "2", {FCVAR_GAMEDLL, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Determine how many rounds between bonus rounds.", 1, 10)
CreateConVar("sts_winner_points", "6", {FCVAR_GAMEDLL, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Determine point reward for winning a round.", 1, 100)
CreateConVar("sts_loser_points", "5", {FCVAR_GAMEDLL, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Determine point reward for losing a round.", 1, 100)
CreateConVar("sts_sudden_death", "1", {FCVAR_GAMEDLL, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Determine if sudden death should be enabled.", 0, 1)
CreateConVar("sts_sudden_death_time", "120", {FCVAR_GAMEDLL, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Determine time until sudden death should begin.", 1, 600)
RunConsoleCommand("sv_gravity", "600") -- reset gravity
RunConsoleCommand("sk_combine_s_kick", "6") -- change combine melee damage
RunConsoleCommand("sbox_noclip", "0")
RunConsoleCommand("sbox_godmode", "0")
RunConsoleCommand("sbox_playershurtplayers", "1")
RunConsoleCommand("sv_noclipspeed", "50")
RunConsoleCommand("sk_citizen_heal_player_min_pct", "100")
RunConsoleCommand("sk_citizen_heal_player_min_forced", "1")
RunConsoleCommand("sk_citizen_heal_ally", "40")
RunConsoleCommand("sk_citizen_heal_ally_delay", "0.5") -- this might've not been set correctly prior and may cause a buff to medics
RunConsoleCommand("sv_playerpickupallowed", "1") -- allow players to pick up objects, some other gamemodes might set this to false
function GM:PlayerSpawnProp(ply, model)
    return false
end

function GM:PlayerSpawnEffect(ply, model)
    return false
end

function GM:PlayerSpawnNPC(ply, npc_type, weapon)
    return false
end

function GM:PlayerSpawnObject(ply, model, skin)
    return false
end

function GM:PlayerSpawnRagdoll(ply, model)
    return false
end

function GM:PlayerSpawnSENT(ply, class)
    return false
end

function GM:PlayerSpawnSWEP(ply, weapon, swep)
    return false
end

function GM:PlayerSpawnVehicle(ply, model, name, table)
    return false
end

function getMapSpawners(mapName)
    local teamNames = {"blue", "red", "green", "yellow"}
    local mapSpawners = {
        ["blue"] = {},
        ["red"] = {},
        ["green"] = {},
        ["yellow"] = {}
    }

    for _, ent in ipairs(ents.FindByClass("info_teleport_destination")) do
        for _, teamName in ipairs(teamNames) do
            -- mapciv_bluespawn1
            if string.find(ent:GetName(), "map" .. mapName .. "_" .. teamName .. "spawn") then table.insert(mapSpawners[teamName], ent) end
        end
    end
    return mapSpawners
end

function fillNextSpawns()
    nextMapSpawnLocations = {
        ["blue"] = {},
        ["red"] = {},
        ["green"] = {},
        ["yellow"] = {}
    }

    local mapSpawners = getMapSpawners(nextMap)
    local teamNames = {"blue", "red", "green", "yellow"}
    for _, teamName in ipairs(teamNames) do
        for _, spawner in ipairs(mapSpawners[teamName]) do
            table.insert(nextMapSpawnLocations[teamName], {spawner:GetPos(), spawner:GetAngles()})
        end
    end
end

-- https://stackoverflow.com/a/15278426
function TableConcat(t1, t2)
    for i = 1, #t2 do
        t1[#t1 + 1] = t2[i]
    end
    return t1
end

-- https://stackoverflow.com/a/641993
function table.shallow_copy(t)
    local t2 = {}
    for k, v in pairs(t) do
        t2[k] = v
    end
    return t2
end

function getTeamIDFromName(teamName1)
    local teamIDs = {"blue", "red", "green", "yellow"}
    for i, name in ipairs(teamIDs) do
        if name == teamName1 then return i end
    end
end

function getTeamNameFromID(teamName1)
    if teamName1 == 0 then return "Spectator" end
    local teamIDs = {"blue", "red", "green", "yellow"}
    return teamIDs[teamName1]
end

cvars.AddChangeCallback("sts_forbid_dev_room", function(convarName, valueOld, valueNew)
    if valueNew == "0" then
        print("gyas")
        for _, ent in ipairs(ents.GetAll()) do
            if ent:GetName() == "dev_secret_button" then
                ent:Fire("unlock")
                break
            end
        end
    else
        for _, ent in ipairs(ents.GetAll()) do
            if ent:GetName() == "dev_secret_button" then
                ent:Fire("lock")
                break
            end
        end
    end
end)
