mobPrefixes = {"blue_", "red_", "green_", "yellow_"}
mobSuffix = "_template"
mobs = {}
-- Define the Mob object
Mob = {}
Mob.__index = Mob
-- Constructor for the Mob
function Mob.new(name, templates, multiplier, delay, spawnfunc)
    -- This is the table we will return
    local EmptyMob = {
        name = name or "",
        templates = templates or {},
        multiplier = multiplier or 1, -- x3
        delay = delay or 1, -- spawning delay for groups
        spawnfunc = spawnfunc or nil
    }

    setmetatable(EmptyMob, Mob) -- Set the metatable of 'EmptyMob' to 'Mob'
    return EmptyMob -- Return the 'EmptyMob' table, whose metatable is 'Mob'. This is our object
end

-- deprecated
function Mob:spawn(teamID, strength)
    local amount = self.multiplier * strength
    PrintMessage(HUD_PRINTTALK, "Spawning " .. self.name .. " with a multiplier of " .. amount .. " for team " .. teamID)
    for _, template in ipairs(self.templates) do
        for _, ent in ipairs(ents.GetAll()) do
            if ent:GetName() == mobPrefixes[teamID] .. template .. mobSuffix then timer.Create("spawner" .. tostring(teamID), self.delay, amount, function() ent:Fire("ForceSpawn") end) end
        end
    end
end

function Mob:getSpawns(teamID, strength)
    local amount = self.multiplier * strength
    local mobsToSpawn = {}
    for _, template in ipairs(self.templates) do
        for _, ent in ipairs(ents.GetAll()) do
            if ent:GetName() == mobPrefixes[teamID] .. template .. mobSuffix then
                for _ = 1, amount do
                    table.insert(mobsToSpawn, {ent, self.delay})
                end
            end
        end
    end
    return mobsToSpawn
end

-- function attachTeamIndicator(npc, teamID)
--     if not IsValid(npc) then return end
--     -- Create the team indicator
--     local indicator = ents.Create("team_indicator")
--     if not IsValid(indicator) then return end
--     local teamColor = team.GetColor(teamID) -- Get the team color
--     -- Position it above the NPC's head
--     local offset = Vector(0, 0, 20) -- Change 90 to the desired height above the NPC
--     indicator:SetPos(npc:GetPos() + offset)
--     indicator:SetParent(npc)
--     indicator:SetLocalPos(offset)
--     indicator:SetColor(Color(255, 0, 0, 255)) -- Set the color based on the team
--     indicator:Spawn()
-- end
-- local function spawnValkyrie(teamName, pos)
--     -- Create the City Scanner
--     local scanner = ents.Create("npc_cscanner")
--     if not IsValid(scanner) then return end
--     scanner:SetPos(pos) -- Modify the position Vector as needed
--     scanner:Spawn()
--     scanner:SetName(teamName)
--     attachTeamIndicator(scanner, teamName)
--     -- Create the first turret and parent it
--     local turret1 = ents.Create("npc_turret_floor")
--     if IsValid(turret1) then
--         turret1:SetPos(scanner:GetPos() + (scanner:GetRight() * 20 + Vector(-15, 0, -25))) -- Position relative to scanner
--         turret1:SetAngles(scanner:GetAngles() + Angle(35, 0, 0))
--         turret1:Spawn()
--         turret1:SetParent(scanner)
--         turret1:SetName(teamName .. "notp")
--         local phys = turret1:GetPhysicsObject()
--         if IsValid(phys) then
--             phys:SetMass(0.01) -- Set mass to almost zero
--         end
--     end
--     -- Create the second turret and parent it
--     local turret2 = ents.Create("npc_turret_floor")
--     if IsValid(turret2) then
--         turret2:SetPos(scanner:GetPos() + (scanner:GetRight() * -20) + Vector(-15, 0, -25)) -- Position relative to scanner
--         turret2:SetAngles(scanner:GetAngles() + Angle(35, 0, 0))
--         turret2:Spawn()
--         turret2:SetParent(scanner)
--         turret2:SetName(teamName .. "notp")
--         local phys = turret2:GetPhysicsObject()
--         if IsValid(phys) then
--             phys:SetMass(0.01) -- Set mass to almost zero
--         end
--     end
-- end
mobs[1] = {
    ["headcrab"] = Mob.new("Headcrab", {"npc_headcrab"}, 1, 1, function(teamID, strength, pos)
        local amount = mobs[1]["headcrab"].multiplier * strength
        for _ = 1, amount do
            local headcrab = ents.Create("npc_headcrab")
            local teamName = getTeamNameFromID(teamID)
            if IsValid(headcrab) then
                headcrab:SetPos(pos)
                headcrab:SetName(teamName .. "teamname")
                headcrab:Spawn()
            end
        end
    end),
    ["blackheadcrab"] = Mob.new("Black Headcrab", {"npc_blackheadcrab"}, 1),
    ["fastheadcrab"] = Mob.new("Fast Headcrab", {"npc_fastheadcrab"}, 1),
    ["manhack"] = Mob.new("Manhack", {"npc_manhack"}, 1, 0.5),
    ["crowbar"] = Mob.new("Crowbar Guy", {"npc_crowbar"}, 1),
    ["stun"] = Mob.new("Stop Resisting", {"npc_stun"}, 1),
    ["torso"] = Mob.new("Zombie Torso", {"npc_torso"}, 1)
}

mobs[2] = {
    ["medic"] = Mob.new("Medic", {"npc_medic"}, 1),
    ["shotgun"] = Mob.new("Shotgun", {"npc_shotgun"}, 1),
    ["combinesmg"] = Mob.new("SMG", {"npc_combinesmg"}, 1),
    ["cop"] = Mob.new("Metrocop", {"npc_cop"}, 1),
    ["zombie"] = Mob.new("Zombie", {"npc_zombie"}, 1),
    ["antlion"] = Mob.new("Antlion", {"npc_antlion"}, 1),
    ["triplefastheadcrab"] = Mob.new("Fast Headcrab (x3)", {"npc_fastheadcrab"}, 3, 0.5),
    ["doublestun"] = Mob.new("Stop Resisting (x2)", {"npc_stun"}, 2, 0.75),
    ["triplemanhack"] = Mob.new("Manhack (x3)", {"npc_manhack"}, 3, 0.3)
}

mobs[3] = {
    ["rocket"] = Mob.new("Rocketeer", {"npc_rocket"}, 1),
    ["barney"] = Mob.new("Barney", {"npc_barney"}, 1),
    ["vort"] = Mob.new("Vortigaunt", {"npc_vort"}, 1),
    ["monk"] = Mob.new("Monk", {"npc_monk"}, 1),
    ["suicide"] = Mob.new("Suicide", {"npc_suicide"}, 1, 0.5),
    -- ["healer"] = Mob.new("Healer", {"npc_healer"}, 1),
    ["doublezombie"] = Mob.new("Zombie (x2)", {"npc_zombie"}, 2, 0.75),
    ["beefcake"] = Mob.new("Beefcake", {"npc_beefcake"}, 1)
}

mobs[4] = {
    ["doublerocket"] = Mob.new("Rocketeer (x2)", {"npc_rocket"}, 2),
    ["quinzombie"] = Mob.new("Zombie (x5)", {"npc_zombie"}, 5, 0.5),
    ["antguard"] = Mob.new("Antlion Guard", {"npc_antguard"}, 1),
    ["valkyrie"] = Mob.new("Valkyrie", {"npc_valkyrie"}, 1, 1),
    ["antlion"] = Mob.new("Antlion (x5)", {"npc_antlion"}, 5, 0.5),
    -- ["healer"] = Mob.new("Healer (x3)", {"npc_healer"}, 3), -- this guy sucks and should be replaced and also no relationship code to make him hate his own team yet
    ["bombsquad"] = Mob.new("Bombing Squad", {"npc_bombsquad"}, 3, 0.3),
    ["elitesquad"] = Mob.new("Elite Squad", {"npc_elitesquad_ar", "npc_elitesquad_shot"}, 1, 1)
}

cvars.AddChangeCallback("sts_episodic_content", function(convarName, valueOld, valueNew)
    if valueNew == 1 then
        mobs[3]["brute"] = Mob.new("Brute", {"npc_brute"}, 1)
        mobs[1]["fasttorso"] = Mob.new("Fast Torso", {"npc_fasttorso"}, 1)
    end

    if valueNew == 0 then
        mobs[3]["brute"] = nil
        mobs[1]["fasttorso"] = nil
    end
end)

function enablePlayerWallhacks()
    hook.Add("PreDrawHalos", "GivePlayersOutlines", function()
        local buckets = {
            red = {},
            blue = {},
            yellow = {},
            green = {},
            white = {}
        }

        -- player pass
        for _, ply in ipairs(player.GetAll()) do
            local t = ply:Team()
            if t == 1 then
                table.insert(buckets.blue, ply)
            elseif t == 2 then
                table.insert(buckets.red, ply)
            elseif t == 3 then
                table.insert(buckets.green, ply)
            elseif t == 4 then
                table.insert(buckets.yellow, ply)
            end
        end

        if #buckets.red > 0 then halo.Add(buckets.red, Color(255, 0, 0), 2, 2, 2, true, true) end
        if #buckets.blue > 0 then halo.Add(buckets.blue, Color(51, 51, 255), 2, 2, 2, true, true) end
        if #buckets.yellow > 0 then halo.Add(buckets.yellow, Color(255, 255, 0), 2, 2, 2, true, true) end
        if #buckets.green > 0 then halo.Add(buckets.green, Color(0, 255, 0), 2, 2, 2, true, true) end
        if #buckets.white > 0 then halo.Add(buckets.white, Color(255, 255, 255), 2, 2, 2, true, true) end
    end)
end

function enableNPCWallhacks()
    hook.Add("PreDrawHalos", "GiveNPCsOutlines", function()
        local buckets = {
            red = {},
            blue = {},
            yellow = {},
            green = {},
            white = {}
        }

        -- npc pass
        for _, ent in ipairs(ents.GetAll()) do
            if not ent:IsNPC() then continue end
            local name = ent:GetNWString("wallhack_col", "white"):lower()
            if name:find("red", 1, true) then
                table.insert(buckets.red, ent)
            elseif name:find("blue", 1, true) then
                table.insert(buckets.blue, ent)
            elseif name:find("yellow", 1, true) then
                table.insert(buckets.yellow, ent)
            elseif name:find("green", 1, true) then
                table.insert(buckets.green, ent)
            elseif name:find("white", 1, true) then
                table.insert(buckets.white, ent)
            end
        end

        if #buckets.red > 0 then halo.Add(buckets.red, Color(255, 0, 0), 2, 2, 2, true, true) end
        if #buckets.blue > 0 then halo.Add(buckets.blue, Color(51, 51, 255), 2, 2, 2, true, true) end
        if #buckets.yellow > 0 then halo.Add(buckets.yellow, Color(255, 255, 0), 2, 2, 2, true, true) end
        if #buckets.green > 0 then halo.Add(buckets.green, Color(0, 255, 0), 2, 2, 2, true, true) end
        if #buckets.white > 0 then halo.Add(buckets.white, Color(255, 255, 255), 2, 2, 2, true, true) end
    end)
end

function disableNPCWallhacks()
    hook.Remove("PreDrawHalos", "GiveNPCsOutlines")
end

function disablePlayerWallhacks()
    hook.Remove("PreDrawHalos", "GivePlayersOutlines")
end