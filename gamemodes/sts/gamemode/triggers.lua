local function SetupMapLua()
    local MapLua = ents.Create("lua_run")
    MapLua:SetName("triggerhook")
    MapLua:Spawn()
    local mobTeleporters = {"red_teleporter", "blue_teleporter", "green_teleporter", "yellow_teleporter"}
    for _, v in ipairs(ents.FindByClass("trigger_teleport")) do
        for _, teleporterName in ipairs(mobTeleporters) do
            if string.find(v:GetName(), teleporterName) then v:Fire("AddOutput", "OnStartTouch triggerhook:RunPassedCode:hook.Run( 'OnTeleport' ):0:-1") end
        end
    end

    for _, ent in ipairs(ents.FindByClass("trigger_push")) do
        -- if "waiting_" is in the name, then it's a trigger_push that needs to be hooked
        if string.find(ent:GetName(), "waiting_") and string.find(ent:GetName(), "_checktrig") then
            ent:Fire("AddOutput", "OnStartTouch triggerhook:RunPassedCode:hook.Run( 'BoxTrigger' ):0:-1")
            ent:Fire("AddOutput", "OnEndTouch triggerhook:RunPassedCode:hook.Run( 'BoxUnTouchTrigger' ):0:-1")
        end
    end
end

local function ResetGameAfterMapReset()
    print("Resetting")
    gameStartedServer = false
    GetConVar("sts_starting_points"):Revert()
    GetConVar("sts_total_rounds"):Revert()
    shouldStartLeverBeLocked()
    if GetConVar("sts_disable_settings_buttons"):GetInt() == 0 then
        for _, ent in ipairs(ents.GetAll()) do
            if ent:GetName() == "waiting_lobby_ready_door" then ent:Fire("close") end
        end
    end
end

hook.Add("InitPostEntity", "SetupMapLua", SetupMapLua)
hook.Add("PostCleanupMap", "SetupMapLua", SetupMapLua)
hook.Add("PostCleanupMap", "ResetGameAfterMapReset", ResetGameAfterMapReset)
hook.Add("OnTeleport", "TestTeleportHook", function()
    local activator, caller = ACTIVATOR, CALLER
    print(activator, caller)
end)

hook.Add("BoxTrigger", "BoxHook", function()
    local activator, caller = ACTIVATOR, CALLER
    local triggerName = caller:GetName()
    local boxName = activator:GetName()
    local teamName = string.match(boxName, "^(%a+)_box%d$") -- ignore anything that isn't a team box (players, NPCs, props also touch the trigger)
    if not teamName then return end
    local teamID = getTeamIDFromName(teamName)
    if not teamID then return end
    local spawnerID = tonumber(triggerName[-1])
    -- print( "teamName =", teamName, "\nteamID =", teamID, "\nspawnerID =", spawnerID, "\nboxName = ", boxName )
    table.insert(teams[teamID].spawners[spawnerID], teams[teamID].cubes["cube" .. boxName[-1]])
end)

hook.Add("BoxUnTouchTrigger", "BoxUnTouchHook", function()
    local activator, caller = ACTIVATOR, CALLER
    local triggerName = caller:GetName()
    local boxName = activator:GetName()
    local teamName = string.match(boxName, "^(%a+)_box%d$")
    if not teamName then return end
    local teamID = getTeamIDFromName(teamName)
    if not teamID then return end
    local spawnerID = tonumber(triggerName[-1])
    -- print( "teamName =", teamName, "\nteamID =", teamID, "\nspawnerID =", spawnerID, "\nboxName = ", boxName )
    for i, cube in ipairs(teams[teamID].spawners[spawnerID]) do
        if cube == teams[teamID].cubes["cube" .. boxName[-1]] then
            table.remove(teams[teamID].spawners[spawnerID], i)
            break
        end
    end
end)
