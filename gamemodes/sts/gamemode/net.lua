include("teamsetup.lua")
-- Server side: listens to the "RequestPoints" message and responds with "SyncPoints"
if SERVER then
    util.AddNetworkString("SyncPoints")
    local function PointsRequest(length, client)
        -- Get the team of the player who sent the request
        local playerTeam = client:Team()
        -- Respond to the client's request
        net.Start("SyncPoints")
        net.WriteInt(teams[playerTeam].points, 32) -- Send the current points of the player's team
        net.Send(client) -- Only send to the client that made the request
    end

    net.Receive("RequestPoints", PointsRequest)
end

-- Client side: updating the points when receiving the "SyncPoints" message from the server
if CLIENT then
    local function UpdatePoints(len)
        points = net.ReadInt(32) -- Updating the points variable with the value sent from the server
    end

    net.Receive("SyncPoints", UpdatePoints)
end

-- Server side: function to periodically send the current points to the members of each team
if SERVER then
    function SendPointsToTeamMembers(teamIndex)
        local teamMembers = team.GetPlayers(teamIndex) -- This function should return a table with all the players of the team
        for _, player in ipairs(teamMembers) do
            net.Start("SyncPoints")
            net.WriteInt(teams[teamIndex].points, 32) -- Sending points to the player, using 32 bits to encode it
            net.Send(player) -- Sends the message to the player
        end
    end

    -- Synchronizing points to team members every 10 seconds, mostly for late joiners because i am lazy
    timer.Create("PointsSyncTimer", 10, 0, function()
        for teamIndex = 1, 4 do
            SendPointsToTeamMembers(teamIndex)
        end
    end)
end

if SERVER then
    util.AddNetworkString("SendBoxInfo")
    function SendBoxInfoToPlayer(player, box)
        net.Start("SendBoxInfo")
        net.WriteInt(box.rarity, 4)
        net.WriteInt(box.strength, 4)
        net.WriteInt(box.level, 4)
        net.WriteString(box.key)
        
        net.Send(player)
    end
end

if CLIENT then
    local function GetBoxInfo(len)
        boxRarity = net.ReadInt(4)
        boxStrength = net.ReadInt(4)
        boxLevel = net.ReadInt(4)
        boxKey = net.ReadString()
    end

    net.Receive("SendBoxInfo", GetBoxInfo)
end

if SERVER then
    util.AddNetworkString("ClearBoxInfo")
    function ClearBox(player)
        net.Start("ClearBoxInfo")
        net.Send(player)
    end
end

if CLIENT then
    local function CleanBox(len)
        boxName = ""
        boxRarity = 0
        boxStrength = 0
        boxLevel = 0
        boxKey = ""
    end

    net.Receive("ClearBoxInfo", CleanBox)
end

if SERVER then
    util.AddNetworkString("ServerToClientMessage")
    function SendServerMessage(message, color, time)
        net.Start("ServerToClientMessage")
        net.WriteString(message) -- The message
        net.WriteColor(color or Color(255, 255, 255)) -- The color of the message
        net.WriteInt(time or -1, 32)
        net.Broadcast() -- or net.Send(ply) if you want to send to a specific player        
    end
end

if CLIENT then
    net.Receive("ServerToClientMessage", function()
        tempMessage = net.ReadString()
        tempMessageColor = net.ReadColor()
        local delay = net.ReadInt(32)
        if delay ~= -1 then timer.Simple(delay, function() tempMessage = "" end) end
    end)
end

if SERVER then
    util.AddNetworkString("TimerEnd")
    function SendTimerEnd(endTick)
        net.Start("TimerEnd")
        net.WriteInt(endTick, 32)
        net.Broadcast()
    end
end

if CLIENT then net.Receive("TimerEnd", function() tickTimerOver = net.ReadInt(32) end) end
if SERVER then
    util.AddNetworkString("StartGame")
    function sendStartToPlayers()
        net.Start("StartGame")
        net.Broadcast()
    end
end

if CLIENT then net.Receive("StartGame", function() gameStarted = true end) end
if SERVER then
    util.AddNetworkString("UpdateSettings")
    function updateSettingsToClients(startPoints, startRounds)
        net.Start("UpdateSettings")
        net.WriteInt(startPoints, 32)
        net.WriteInt(startRounds, 32)
        net.Broadcast()
    end
end

if CLIENT then
    net.Receive("UpdateSettings", function()
        startingPoints = net.ReadInt(32)
        startingRounds = net.ReadInt(32)
    end)
end

if SERVER then
    util.AddNetworkString("UpdateGravity")
    function updateGravityToClients(gravity)
        net.Start("UpdateGravity")
        net.WriteFloat(gravity)
        net.Broadcast()
        for _, ply in ipairs(player.GetAll()) do
            ply:SetGravity(gravity)
        end
    end
end

if CLIENT then net.Receive("UpdateGravity", function() globalGravity = net.ReadFloat() end) end
if SERVER then
    util.AddNetworkString("Wallhacks")
    function enableWallhacksGlobally()
        net.Start("Wallhacks")
        net.Broadcast()
    end

    util.AddNetworkString("DisableWallhacks")
    function disableWallhacksGlobally()
        net.Start("DisableWallhacks")
        net.Broadcast()
    end
end

if CLIENT then
    net.Receive("Wallhacks", function() enableWallhacks() end)
    net.Receive("DisableWallhacks", function() disableWallhacks() end)
end


if SERVER then
    util.AddNetworkString("ShieldHitEffect")
end
if CLIENT then
    net.Receive("ShieldHitEffect", function()
    local pos = net.ReadVector()
    local ed = EffectData()
    ed:SetOrigin(pos)
    util.Effect("cball_bounce", ed)
    end)
end
if SERVER then
    -- TODO: Check if actually needed (gmod content update)
    hook.Add("Initialize", "RegisterAntlionWorker", function()
        local npcList = list.GetForEdit("NPC")
        
        npcList["npc_antlion_worker"] = {
            Name = "Antlion Worker",
            Class = "npc_antlion_worker",
            Category = "Half-Life 2"
        }
        print("Registered npc_antlion_worker in NPC list")
    end)
end