function beginTestFight()
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
    local teamsToSpawn = {1, 2, 3, 4}
    local teamMobs = {} -- {1 = ..., 4 = ...}
    local delay
    local largestDelay = 0
    local rarityNames = {"Common", "Uncommon", "Rare", "Legendary"}
    -- kept local rather than written into teams[id].spawners: entries put there are never removed
    -- (the box untouch hook only removes real cubes), so they leaked into every later real round
    local testSpawners = {}
    for _, id in pairs(teamsToSpawn) do
        testSpawners[id] = {}
        for i = 1, 4 do
            local level = math.random(1, 4)
            local keys = {}
            -- get keys of mobs[level]
            for key, _ in pairs(mobs[level]) do
                table.insert(keys, key)
            end

            local chosenmob = keys[math.random(1, #keys)]
            local mob = mobs[level][chosenmob]
            local strength = math.random(1, 4)
            testSpawners[id][i] = {{
                ["mob"] = mob,
                ["key"] = chosenmob,
                ["multipler"] = 1,
                ["strength"] = strength
            }}

            -- getSpawns() emits one NPC per template per (multiplier * strength), so a 2-template
            -- mob like the elite squad is worth double what the strength number alone suggests
            local count = #mob.templates * mob.multiplier * strength
            PrintMessage(HUD_PRINTTALK, string.format("[Test] %-6s cube %d: %s (%s) str %d -> %d NPC every %.2fs", teams[id].name, i, mob.name, rarityNames[level] or "?", strength, count, mob.delay))
        end
    end

    for _, id in pairs(teamsToSpawn) do
        for _, spawner in ipairs(testSpawners[id]) do
            if teamMobs[id] == nil then
                teamMobs[id] = spawner[1].mob:getSpawns(id, spawner[1].strength)
            else
                TableConcat(teamMobs[id], spawner[1].mob:getSpawns(id, spawner[1].strength))
            end
        end

        if teamMobs[id] then PrintMessage(HUD_PRINTTALK, string.format("[Test] %-6s fielding %d NPC total", teams[id].name, #teamMobs[id])) end
    end

    for i, theMobs in pairs(teamMobs) do
        delay = 0
        for _, mob in ipairs(theMobs) do
            delay = delay + mob[2]
            timer.Simple(delay, mob[1])
        end

        if delay > largestDelay then largestDelay = delay end
    end

    PrintMessage(HUD_PRINTTALK, string.format("[Test] last mob lands at %.1fs", largestDelay))

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

    timer.Simple(largestDelay, function()
        -- PrintMessage(HUD_PRINTTALK, "checking for win")
        if GetConVar("sts_sudden_death"):GetInt() == 1 then
            timer.Create("SuddenDeath", GetConVar("sts_sudden_death_time"):GetInt(), 1, function()
                suddenDeath = true
                SendServerMessage("Sudden Death has started! Kill all enemy mobs to win!", Color(255, 255, 255), 3)

                for aliveteam, aliveState in pairs(alive) do
                    if aliveState == -1 then continue end -- already eliminated
                    for i, ply in pairs(team.GetPlayers(getTeamIDFromName(winnerShorter[aliveteam]))) do
                        ply:SetHealth(100)
                        ply:Give("weapon_pistol")
                        ply:SetAmmo(1000, "Pistol")
                        local spawns = nextMapSpawnLocations[getTeamNameFromID(ply:Team())]
                        if spawns and #spawns > 0 then
                            local spawn = spawns[(i - 1) % #spawns + 1]
                            ply:SetPos(spawn[1])
                            ply:SetEyeAngles(spawn[2])
                        end
                    end
                end

                enablePlayerWallhacksGlobally()
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
                        if string.sub(ent:GetName(), 1, #aliveteam) == aliveteam and ent:IsValid() and ent:IsNPC() then
                            for i, ply in pairs(team.GetPlayers(getTeamIDFromName(winnerShorter[aliveteam]))) do
                                ent:AddEntityRelationship(ply, D_LI, 10)
                            end
                        elseif ent:IsNPC() and ent:IsValid() then
                            for i, ply in pairs(team.GetPlayers(getTeamIDFromName(winnerShorter[aliveteam]))) do
                                ent:AddEntityRelationship(ply, D_HT, 10)
                            end
                        end
                    end
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

concommand.Add("watch_random_game", function(ply, cmd, args) beginTestFight() end, nil, nil, FCVAR_CHEAT)
