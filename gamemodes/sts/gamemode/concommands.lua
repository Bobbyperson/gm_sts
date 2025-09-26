-- Define team properties
local teamProperties = {
    [1] = {
        color = Vector(0, 0, 1.0),
        outfitterColor = "28 141 255",
        namePrefix = "Blueply"
    },
    [2] = {
        color = Vector(1.0, 0, 0),
        outfitterColor = "255 30 30",
        namePrefix = "Redply"
    },
    [3] = {
        color = Vector(0.0, 1.0, 0.0),
        outfitterColor = "30 255 30",
        namePrefix = "Greenply"
    },
    [4] = {
        color = Vector(1.0, 1.0, 0.0),
        outfitterColor = "255 255 0",
        namePrefix = "Yellowply"
    },
    [0] = {
        color = Vector(0.0, 0.0, 0.0),
        outfitterColor = "0 0 0",
        namePrefix = ""
    }
}

function setTeamFull(ply, teamID)
    -- Clearer message
    -- local teamEmpty = team.NumPlayers(teamID) == 0
    -- print("The team you want to join IS" .. (teamEmpty and "" or " NOT") .. " empty.")
    -- Setting the team
    ply:SetTeam(teamID)
    -- Using team properties dictionary to reduce code repetition
    local props = teamProperties[teamID]
    ply:SetKeyValue("targetname", props.namePrefix .. ply:GetName())
    -- Setting the player color
    if GetConVar("sts_outfitter_support"):GetInt() == 1 then
        ply:SetKeyValue("rendercolor", props.outfitterColor)
    else
        ply:SetPlayerColor(props.color)
        ply:SetModel("models/player/police.mdl")
    end

    shouldStartLeverBeLocked()
end

concommand.Add("set_team", function(ply, cmd, args)
    local input = tonumber(args[1])
    if input == nil or (input > 4 or input < 0) then
        print("0 - No team\n1 - Blue\n2 - Red\n3 - Green\n4 - Yellow")
        return
    end

    if team.NumPlayers(input) > 3 then
        ply:PrintMessage(HUD_PRINTTALK, "That team is full!")
        return
    end

    if ply:Team() ~= 0 and gameStartedServer and GetConVar("sts_allow_team_swapping"):GetInt() == 0 then
        ply:PrintMessage(HUD_PRINTTALK, "You can't change teams midgame!")
        return
    end

    if GetConVar("sts_random_teams"):GetInt() ~= 0 then
        ply:PrintMessage(HUD_PRINTTALK, "Teams are locked!")
        return
    end

    setTeamFull(ply, input)
end)

concommand.Add("pntadd", function(ply, cmd, args)
    local input = tonumber(args[1])
    if input == nil then
        print("Please enter a number")
        return
    end

    for i = 1, 4 do
        teams[i].points = teams[i].points + input
    end

    print("Point Boost")
end, nil, nil, FCVAR_CHEAT)

concommand.Add("flagspawn", function(args)
    for k, v in ipairs(ents.GetAll()) do
        if v:GetName() == "mapctf_flag_template" then v:Fire("ForceSpawn") end
    end
end, nil, nil, FCVAR_CHEAT)

concommand.Add("batteryspawn", function(args)
    for k, v in ipairs(ents.GetAll()) do
        if v:GetName() == "mapctf_battery_tp1" then v:Fire("ForceSpawn") end
    end
end, nil, nil, FCVAR_CHEAT)

concommand.Add("reset_game", function(ply, cmd, args) gameReset() end, nil, nil, FCVAR_CHEAT)
concommand.Add("reset_game_solo", function(ply, cmd, args)
    if tonumber(player.GetCount()) == 1 and gameStartedServer then
        print("\n\n\nYou are alone, so you can reset the map \nThanks for cleaning up the server! \n\n-Tergative\n\n\n\n")
        gameReset()
    else
        print("Either you are not alone or the game has not started.")
    end
end)