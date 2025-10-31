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
local function FindNearestEnemy(npc, radius)
    local nearest = nil
    local minDistSqr = math.huge
    for _, ent in ipairs(ents.FindInSphere(npc:GetPos(), radius)) do
        if IsValid(ent) and ent:IsNPC()
        and npc:Disposition(ent) == D_HT
        and npc:GetPos():DistToSqr(ent:GetPos()) < minDistSqr then
            nearest = ent
            minDistSqr = distSqr
        end
    end
    if nearest == nil then
        print("FindNearestEnemy couldn't find nearest! Probably no enemies in range")
        return
    end
    return nearest
end


function ToggleTeamDamage(inputbool)
    if inputbool == true then
        if hook.GetTable().EntityTakeDamage == nil or hook.GetTable().EntityTakeDamage.DisableFriendlyFire == nil then
            hook.Add("EntityTakeDamage", "DisableFriendlyFire", function(ent, dmginfo)
                local attacker = dmginfo:GetAttacker()
                if IsValid(attacker) and IsValid(ent) and attacker.GetName and attacker:GetName() == ent:GetName() then
                    return true
                end
            end)
        else
            print("Friendly fire has already been disabled.")
            return
        end
    else
        if hook.GetTable().EntityTakeDamage and hook.GetTable().EntityTakeDamage.DisableFriendlyFire then
            hook.Remove("EntityTakeDamage", "DisableFriendlyFire")
        end
    end
end

-- This part uses a point_template on the map with the name "team_indicator_template" to template a team indicator brush
-- this point_template can be found in a new empty room next to all the team's mob rooms
teamIndicatorQueue = {}
hook.Add("OnEntityCreated", "TeamIndicatorCatcherHook", function(ent)
        if teamIndicatorQueue[1] == nil then
            return
        end
        -- Gotta wait for indicator to be created (or something idk it just works)
        timer.Simple(1 / 66, function()
            if IsValid(ent) and ent.GetName and string.find(ent:GetName(), "cloned_indicator") then
                local targetQueueEntry = teamIndicatorQueue[1]
                if IsValid(targetQueueEntry[1]) then
                    ent:SetPos(targetQueueEntry[1]:GetPos())
                    ent:SetParent(targetQueueEntry[1])
                    ent:SetLocalPos(Vector(0, 0, targetQueueEntry[3]))
                    ent:SetColor(team.GetColor(targetQueueEntry[2]))
                    table.remove(teamIndicatorQueue, 1)
                end
            end
        end)
    end)
local function AttachTeamIndicator(target_entity, teamID, height_offset)
    local templator
    for _ , ent in pairs(ents.GetAll()) do
        if ent:GetName() == "team_indicator_templator" then
            templator = ent
            break
        end
    end
    if templator == nil then
        print("WARNING: AttachTeamIndicator function couldn't find any node named 'team_indicator_templator' to use for templating team indicators")
        return
    end
    table.insert(teamIndicatorQueue, {target_entity, teamID, height_offset})
    --print("AttachTeamIndicator called!")
    templator:Fire("ForceSpawn", "", 0)
end

--[[
function attachTeamIndicator(npc, teamID)
     if not IsValid(npc) then return end
     -- Create the team indicator
     local indicator = ents.Create("team_indicator")
     if not IsValid(indicator) then return end
     local teamColor = team.GetColor(teamID) -- Get the team color
    -- Position it above the NPC's head
     local offset = Vector(0, 0, 20) -- Change 90 to the desired height above the NPC
     indicator:SetPos(npc:GetPos() + offset)
     --indicator:SetParent(npc)
     
     indicator:SetColor(teamColor) -- Set the color based on the team
     indicator:Spawn()
 end

]]--

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

--headcrab spawn function: function(teamID, strength, pos)
        --local amount = mobs[1]["headcrab"].multiplier * strength
        --for _ = 1, amount do
            --local headcrab = ents.Create("npc_headcrab")
            --local teamName = getTeamNameFromID(teamID)
            --if IsValid(headcrab) then
                --headcrab:SetPos(pos)
               -- headcrab:SetName(teamName .. "teamname")
               -- headcrab:Spawn()
           -- end
        --end
   -- end


---------------------------------------------------------------------START OF AEGIS SHIELD UNIT CODE------------------------------------------------------------------------------------
-- local function DrawDebugSphere(ent, useBoundingBox, radius, duration, color)
--     if not IsValid(ent) then return end
--     if useBoundingBox == true then
--         local entCenter = ent:OBBCenter()
--         local radius = entCenter:Distance(ent:OBBMaxs())
--     else
--         local radius = radius
--     end
--     local pos = ent:GetPos()
--     debugoverlay.Sphere(pos, radius, duration or 1, color or Color(0, 0, 255, 255), true)
-- end

local function RayIntersectsSphere(rayOrigin, rayDirection, sphereCenter, sphereRadius)
    -- Get the vector from the ray origin to the sphere center
    local originToCenter = rayOrigin - sphereCenter

    -- Coefficients of the quadratic equation
    local dirDot = rayDirection:Dot(rayDirection) -- Usually = 1 if direction is normalized
    local ocDot = originToCenter:Dot(rayDirection) -- How much the vector to the center points in the ray direction
    local centerDot = originToCenter:Dot(originToCenter) -- Squared distance from ray origin to sphere center

    -- Quadratic formula terms
    local a = dirDot
    local b = 2 * ocDot
    local c = centerDot - sphereRadius * sphereRadius

    -- Discriminant: tells us whether the ray hits the sphere
    local discriminant = b * b - 4 * a * c

    -- If the discriminant is negative, the ray misses the sphere
    if discriminant < 0 then
        return nil
    end

    -- Find the intersection distances along the ray
    local sqrtDiscriminant = math.sqrt(discriminant)
    local t1 = (-b - sqrtDiscriminant) / (2 * a)
    local t2 = (-b + sqrtDiscriminant) / (2 * a)

    -- Return the t values (how far from the origin the hits are)
    return t1, t2
end

-- These globals are essential for the Aegis shield unit
-- ShieldRadius controls how big the shield hitbox is, it won't change the size of the model itself though.
-- if you wanna make it bigger/smaller go to addons/gm_sts-main/lua/entities/bubble_shield and change the scale of the entity model
shieldRadius = 100
shieldregistry = {}

-- This function is to activate the bullet filtering logic of the Aegis Shield units
-- This whole thing kinda seems unoptimized af, and it would be much better if we could ignore multiple entities in the bullet data structure instead of just one (i wonder why is it like this? its basically useless)
-- this is what im talking about; https://github.com/Facepunch/garrysmod-requests/issues/1897

local function AddShieldBulletHook()
    print("ShieldBulletFilter hook has been added")
    hook.Add("PostEntityFireBullets", "ShieldBulletFilter", function(attacker, data)
        local bulletstart = data.Trace["StartPos"]
        --using data.Trace["hitpos"] fucks up the intersectRay below for some reason that is beyond me
        local dir = data.Trace["Normal"]:GetNormalized()
        local bulletendpos = bulletstart + (dir * 10000) -- I just randomly picked 10000 as the length, may need to lengthen it idk. 

        if #shieldregistry == 0 then
            hook.Remove("PostEntityFireBullets", "ShieldBulletFilter")
            print("No shields in shield registry! Hook removed!")
            return true
        end

        local closestShield = {
            dist2 = nil,
            pos = nil,
            indx = nil
        }
        -- I'm iterating through the shield registry backwards to be able to remove any invalid shields
        -- (Note for myself BOT Zach: this is cause removing a table entry while iterating forwards will result in fucky indexing / skipped entries due to the rest of the table shifting after removal)
        -- find closest shield
        for i = #shieldregistry, 1, -1 do
            if not IsValid(shieldregistry[i][1]) then
                --print("Shieldregistry[" .. i .. "] aint valid no more! Removing it...")
                table.remove(shieldregistry, i)
                continue
            end

            local vecToShield = shieldregistry[i][1]:GetPos() - bulletstart
            local distToShield = vecToShield:Length()

            local toDirNorm = vecToShield / distToShield

            -- Here we check if the bullet's angle comes within a certain threshold to the current shield
            -- If the bullet angle is greater than our threshold, we skip to the next shield to avoid unneccessary calculations

            local theta = math.atan(shieldRadius / distToShield)
            local minDot = math.cos(theta)

            --print("Minimum angle:".. tostring(minDot))
            --print("Actual angle dot: " .. tostring(dir:Dot(toDirNorm)))
            if (dir:Dot(toDirNorm)) < minDot then
                continue
            end

            local shieldTeam = shieldregistry[i][2]
            -- if the current shield is friendly to the attacker, skip to the next shield
            if shieldTeam == attacker:GetName() then continue end

            local result1, _ = RayIntersectsSphere(bulletstart, dir, shieldregistry[i][1]:GetPos(), shieldRadius)
            -- I dont think result1 should ever be nil here because of the dot product check above, but imma check it anyways
            if result1 == nil then
                --debugoverlay.Line(bulletstart, bulletendpos, 0.2, Color(255, 0, 0, 255), true)
                --print("RAY DIDN'T HIT INTERSECT SPHERE") 
                continue
            end

            local intersect1 = bulletstart + dir * result1
            --debugoverlay.Sphere(intersect1, 4, 1, Color(255, 255, 0), true, 1)
            local rayDist = bulletstart:DistToSqr(intersect1)
            if closestShield.dist2 == nil or rayDist < closestShield.dist2 then
                closestShield = {dist2 = rayDist, pos = intersect1, indx = i}
            end
        end

        -- if we didnt find any shields, return true and fire the bullet normally
        if closestShield.indx == nil then
            return true
        end

        -- gotta check to make sure theres nothing in front of the shield we should hit first
        local tr = util.TraceLine({
            start = bulletstart,
            endpos = bulletendpos,
            filter = attacker,
            mask = MASK_SHOT
        })
        local hitpos = tr.HitPos
        local traceDist = bulletstart:DistToSqr(hitpos)

        -- if the bullet trace hits an object that is closer than the ray intersect, fire da bullet as normal
        if traceDist < closestShield.dist2 then

            --Useful debuging, must have developer = 1 convar set in order to see
            --DrawDebugSphere(shieldregistry[closestShield.indx][1], false, shieldRadius, 1, Color(255, 0, 200))
            --debugoverlay.Line(bulletstart, bulletendpos, 0.2, Color(255, 0, 200), true)
            return true
        end

        -- if not, return false to cancel da bullet
        -- you know, you'd think that you wouldn't be able to cancel the bullet here in 'PostEntityFireBullets', but you can!

        --DrawDebugSphere(shieldregistry[closestShield.indx][1], false, shieldRadius, 1, Color(0, 255, 0, 255))
        --debugoverlay.Line(bulletstart, bulletendpos, 0.2, Color(0, 255, 0, 255), true)
        sound.Play("weapons/fx/rics/ric2.wav", closestShield.pos, 67, math.random(95, 105))
        local ed = EffectData()
        ed:SetOrigin(closestShield.pos)
        util.Effect("cball_bounce", ed)
        local damage = data["Damage"]
        if damage == 0 then
            local ammoTypeID = game.GetAmmoID(data["AmmoType"])
            damage = game.GetAmmoNPCDamage(ammoTypeID)
        end
        -- shield health -= damage
        if shieldregistry[closestShield.indx] == nil then
            print("Shield was nil!")
            return true
        end
        shieldregistry[closestShield.indx][3] = shieldregistry[closestShield.indx][3] - damage
        --print("Shield shot, current health is: " .. shieldregistry[i][3])
        if shieldregistry[closestShield.indx][3] <= 0 then
            sound.Play("ambient/levels/outland/combineshieldactivate.wav", closestShield.pos, 100 , 100)
            shieldregistry[closestShield.indx][1]:Remove()
        end
        return false
    end)
end

local function AegisShieldUnitSpawn(teamID, delay, pos)

    timer.Simple(delay, function()
        local combine = ents.Create("npc_combine_s")
        local teamname = getTeamNameFromID(teamID)
        combine:SetName(teamname .. "team")
        combine:SetKeyValue("additionalequipment", "weapon_smg1")
        combine:SetKeyValue("squadname", teamname)
        combine:SetPos(pos)
        combine:Spawn()

        local shield = ents.Create("bubble_shield")
        shield:SetPos(combine:GetPos())
        shield:SetParent(combine)
        shield:Spawn()
        local shieldHealth = 220
        local newShieldEntry = {shield, teamname .. "team", shieldHealth}
        table.insert(shieldregistry, newShieldEntry)
        timer.Simple(0.2, function()
            AttachTeamIndicator(combine, teamID, 130)
        end)
        if hook.GetTable()["PostEntityFireBullets"] == nil or hook.GetTable()["PostEntityFireBullets"]["ShieldBulletFilter"] == nil then
            AddShieldBulletHook()
        end
    end)
end

------------------------------------------------------------------END OF AEGIS SHIELD UNIT CODE-------------------------------------------------------------------------------------

local function RollermineSpawn(teamID, delay, pos)
    timer.Simple(delay, function()
        local rollermine = ents.Create("npc_rollermine")
        local teamname = getTeamNameFromID(teamID)
        -- 1282 = long visibility + gag idle sounds + think outside pvs
        rollermine:AddSpawnFlags(1282)
        rollermine:SetPos(pos)
        rollermine:SetColor(team.GetColor(teamID))
        rollermine:SetName(teamname .. "team")
        rollermine:SetHealth(100)
        rollermine:SetKeyValue("squadname", teamname)
        rollermine:SetKeyValue("uniformsightdist", "1")
        rollermine:SetMaxLookDistance(6000)
        rollermine:Spawn()
        local minehealth = 20

        -- rollermines tend to bounce around alot, and so on the "dont look up" map they can get out of bounds frequently
        local timeTilAutoKill = 90
        timer.Simple(timeTilAutoKill, function()
            if IsValid(rollermine) then
                local killattack = DamageInfo()
                killattack:SetDamage(9999)
                killattack:SetAttacker(game.GetWorld())
                killattack:SetInflictor(game.GetWorld())
                killattack:SetDamageType(DMG_BLAST)
                killattack:SetDamagePosition(rollermine:GetPos())
                killattack:SetDamageForce(Vector(0,0,0))
                rollermine:TakeDamageInfo(killattack)
            end
        end)
        local timername = "RollermineChase_" .. rollermine:EntIndex()
        timer.Create(timername, 5, 0, function()
            if IsValid(rollermine) then
                --local nearest = FindNearestEnemy(rollermine, 6000)
                local currentEnemy = rollermine:GetEnemy()
                if not IsValid(currentEnemy) then
                    local nearest = FindNearestEnemy(rollermine, 6000)
                    rollermine:SetEnemy(nearest)
                    rollermine:UpdateEnemyMemory(nearest, nearest:GetPos())
                end
                rollermine:SetSchedule(SCHED_CHASE_ENEMY)
            else
                timer.Remove(timername)
            end
        end)
        local rollermineDamageHook = "RollermineDamageHook_" .. rollermine:EntIndex()
        hook.Add("EntityTakeDamage", rollermineDamageHook, function(ent, dmginfo)
            if not IsValid(rollermine) then
                hook.Remove("EntityTakeDamage", rollermineDamageHook)
            end
            if ent == rollermine then
                minehealth = minehealth - dmginfo:GetDamage()
                if minehealth <= 0 then
                    hook.Remove("EntityTakeDamage", "RollermineDamageHook_" .. rollermine:EntIndex())
                    local killattack = DamageInfo()
                    killattack:SetDamage(9999)
                    killattack:SetAttacker(game.GetWorld())
                    killattack:SetInflictor(game.GetWorld())
                    killattack:SetDamageType(DMG_BLAST)
                    killattack:SetDamagePosition(rollermine:GetPos())
                    killattack:SetDamageForce(Vector(0,0,0))
                    rollermine:TakeDamageInfo(killattack)
                end
            end
        end)
    end)
end

local function CombineSniperSpawn(teamID, delay, pos)
    timer.Simple(delay, function()
        local sniper_mount = ents.Create("npc_citizen")
        local sniper = ents.Create("npc_sniper")
        local teamname = getTeamNameFromID(teamID)
        if IsValid(sniper) and IsValid(sniper_mount) then
            sniper:SetKeyValue("squadname", teamname)
            sniper:SetPos(pos)
            sniper:SetName(teamname .. "team")
            sniper:SetColor(Color(255, 255, 255, 0))
            sniper:SetRenderMode(RENDERMODE_TRANSALPHA)
            sniper:Spawn()
            sniper_mount:SetKeyValue("squadname", teamname)
            sniper_mount:SetKeyValue("citizentype", "3")
            sniper_mount:SetKeyValue("additionalequipment", "weapon_smg1")
            sniper_mount:SetKeyValue("ammosupply", 0)
            sniper_mount:AddSpawnFlags(SF_NPC_NO_WEAPON_DROP)
            sniper_mount:SetPos(pos)
            sniper_mount:SetName(teamname .. "team")
            sniper_mount:Spawn()
            sniper_mount:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
            timer.Simple(0.2, function()
                AttachTeamIndicator(sniper, teamID, 80)
            end)

            -- sniper is not parented to it's mount because (i think) it would get pushed by the map spawn push trigger away from its parent, resulting in quite a large
            -- offset from where the sniper and its mount are
            local mountTimerName = "MountTimer_" .. sniper:EntIndex()
            timer.Create(mountTimerName, 1 / 66, 0, function()
                if IsValid(sniper) and  IsValid(sniper_mount) then
                    sniper:SetPos(sniper_mount:GetPos())
                    sniper:SetAngles(sniper_mount:GetAngles())
                elseif IsValid(sniper) then
                    sniper:Remove()
                    timer.Remove(mountTimerName)
                end
            end)
            local sniperhealth = sniper:Health()
            hook.Add("EntityTakeDamage", "SniperDamageHook_" .. sniper:EntIndex(), function(ent, dmginfo)
                if ent == sniper then
                    sniperhealth = sniperhealth - dmginfo:GetDamage()
                    if sniperhealth <= 0 then
                        hook.Remove("EntityTakeDamage", "SniperDamageHook_" .. sniper:EntIndex())
                        local killattack = DamageInfo()
                        if not IsValid(sniper_mount) then return end
                        killattack:SetDamage(9999)
                        killattack:SetAttacker(game.GetWorld())
                        killattack:SetInflictor(game.GetWorld())
                        killattack:SetDamageType(DMG_BLAST)
                        killattack:SetDamagePosition(sniper_mount:GetPos())
                        killattack:SetDamageForce(Vector(0,0,0))
                        sniper_mount:TakeDamageInfo(killattack)
                        sniper:Remove()
                    end
                end
            end)
        end
    end)
end





local function StalkerSpawn(teamID, delay, pos)
    timer.Simple(delay, function()
        local stalker = ents.Create("npc_stalker")
        stalker:SetPos(pos)
        local teamname = getTeamNameFromID(teamID)
        stalker:SetName(teamname .. "team")
        stalker:SetKeyValue("squadname", teamname)
        stalker:SetKeyValue("BeamPower", 1)
        stalker:Spawn()
        timer.Simple(0.2, function()
            AttachTeamIndicator(stalker, teamID, 80)
        end)
        stalker:SetSaveValue("m_iPlayerAggression", 5)

        local timername = "StalkerAttackCenterPoint" .. stalker:EntIndex()
        timer.Create(timername, 0.2, 0, function()
            if IsValid(stalker) then

                -- maybe not getting the save table at all would be more efficient...

                local save_table = stalker:GetSaveTable()
                -- Check if the beam is active
                if save_table.m_pBeam then
                    -- Get the current enemy
                    local enemy = stalker:GetEnemy()
                    -- Make sure the enemy is valid
                    if IsValid(enemy) then
                        -- Set the laser target to the enemy's OBB center
                        local target_pos = enemy:OBBCenter()
                        stalker:SetSaveValue("m_vLaserTargetPos", enemy:GetPos() + target_pos)
                    end
                end
            else
                timer.Remove(timername)
            end
        end)
    end)
end
-------------------------------------------------------------GRENADIER UNIT CODE START-------------------------------------------------------------------

function throwGrenadeAtEnemy(ent)
    if not IsValid(ent) then
        return
    end
    if ent:GetClass() ~= "npc_combine_s" then
        return
    end
    local currentEnemy = ent:GetEnemy()
    if currentEnemy == nil or not IsValid(currentEnemy) then
        currentEnemy = FindNearestEnemy(ent, 6000)
        if not IsValid(currentEnemy) then
            print("FUNC throwGrenadeAtEnemy: Couldn't find anything to throw a grenade at!")
            return
        end
    else
        -- I couldn't get them to just throw the grenade at their current enemy, so I did info_target hack
        local world = game.GetWorld()
        local grenadetarget = ents.Create("info_target")
        grenadetarget:SetPos(currentEnemy:GetPos())
        grenadetarget:SetName("grenade_target_" .. grenadetarget:EntIndex())
        --print("Grenade target name: " .. grenadetarget:GetName())
        grenadetarget:Spawn()
        timer.Simple(0.1, function()
            if not IsValid(grenadetarget) or not IsValid(ent) then return end
            ent:Input("ThrowGrenadeAtTarget", world, world, grenadetarget:GetName())
            timer.Simple(1, function()
                --print(grenadetarget:GetName() .. " removed!")
                grenadetarget:Remove()
            end)
        end)
    end
end

-- These guys frequently kill their teammates, so do the stalkers. I added a console command to disable team damage; nofriendlyfire true/false
local function GrenadierSpawn(teamID, delay, pos)
    timer.Simple(delay, function()
        local teamname = getTeamNameFromID(teamID)
        local combineunit = ents.Create("npc_combine_s")
        combineunit:SetPos(pos)
        combineunit:SetKeyValue("additionalequipment", "weapon_smg1")
        combineunit:SetName(teamname .. "team")
        combineunit:SetKeyValue("squadname", teamname)
        combineunit:AddSpawnFlags(SF_NPC_NO_WEAPON_DROP)
        combineunit:Spawn()
        timer.Simple(0.2, function()
            AttachTeamIndicator(combineunit, teamID, 80)
        end)
        local grenadierhead = ents.Create("prop_dynamic")
        grenadierhead:SetModel("models/Combine_Helicopter/helicopter_bomb01.mdl")
        grenadierhead:SetModelScale(0.5, 0.00001)
        grenadierhead:SetPos(pos)
        grenadierhead:SetMoveType(MOVETYPE_NONE)
        grenadierhead:SetSolid(SOLID_NONE)
        grenadierhead:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
        grenadierhead:FollowBone(combineunit, 14)
        local ammoStripTimerName = "AmmoStripTimer_" .. combineunit:EntIndex()
        timer.Create(ammoStripTimerName, 0.2, 0, function()
            if not IsValid(combineunit) then
                timer.Remove("ammostriptimer_")
                return
            end
            local weapon = combineunit:GetActiveWeapon()
            if not IsValid(weapon) then
                timer.Remove(ammoStripTimerName)
                return
            end
            weapon:SetClip1(0)
            weapon:SetClip2(0)
        end)
        local throwNadeTimerName = "CombineThrowNades_" .. combineunit:EntIndex()
        timer.Create(throwNadeTimerName, 3, 0, function()
            if IsValid(combineunit) then
                local currentEnemy = combineunit:GetEnemy()
                if not IsValid(currentEnemy) then
                    currentEnemy = FindNearestEnemy(combineunit, 6000)
                end
                if IsValid(currentEnemy) then
                    local distance = 900
                    distance = distance * distance
                    if combineunit:GetPos():DistToSqr(currentEnemy:GetPos()) > distance then
                        --print("Grenadier out of range! moving closer...")
                        local vecToEnemy = currentEnemy:GetPos() - combineunit:GetPos()
                        vecToEnemy = vecToEnemy:GetNormalized()
                        combineunit:SetLastPosition(combineunit:GetPos() + (vecToEnemy * 200))
                        combineunit:SetSchedule(SCHED_FORCED_GO_RUN)
                    else
                        throwGrenadeAtEnemy(combineunit)
                    end
                end
            else
                timer.Remove(throwNadeTimerName)
            end
        end)

        local grenadierThinkHookName = "StopGrenadierReload_" .. combineunit:EntIndex()
        hook.Add("Think", grenadierThinkHookName , function()
            if IsValid(combineunit) and IsValid(combineunit:GetActiveWeapon()) then
                local sched = combineunit:GetCurrentSchedule()
                if sched == SCHED_HIDE_AND_RELOAD or sched == SCHED_RELOAD or sched == 200 then
                    combineunit:SetSchedule(SCHED_FAIL) -- Or SCHED_ALERT_FACE
                end
            else
                hook.Remove("Think", grenadierThinkHookName)
            end
        end)
    end)
end

------------------------------------------------------------------GRENADIER UNIT CODE END----------------------------------------------------------------
local function AntlionGuardSpawn(teamID, delay, pos)
    timer.Simple(delay, function()
        local guard = ents.Create("npc_antlionguard")
        local teamname = getTeamNameFromID(teamID)
        guard:SetPos(pos)
        guard:SetName(teamname .. "team")
        guard:Spawn()
        timer.Simple(0.2, function()
            AttachTeamIndicator(guard, teamID, 120)
        end)
        -- This variable controls how long the guards take to automatically die
        local timeTilAutoKill = 25
        timer.Simple(timeTilAutoKill, function()
            if IsValid(guard) then
                local killattack = DamageInfo()
                killattack:SetDamage(9999)
                killattack:SetAttacker(game.GetWorld())
                killattack:SetInflictor(game.GetWorld())
                killattack:SetDamageType(DMG_BLAST)
                killattack:SetDamagePosition(guard:GetPos())
                killattack:SetDamageForce(Vector(0,0,0))
                guard:TakeDamageInfo(killattack)
            end
        end)
    end)
end

local function HunterSpawn(teamID, delay, pos)
    timer.Simple(delay, function()
        local hunter = ents.Create("npc_hunter")
        local teamname = getTeamNameFromID(teamID)
        hunter:SetPos(pos)
        hunter:SetName(teamname .. "team")
        hunter:Spawn()
        timer.Simple(0.2, function()
            AttachTeamIndicator(hunter, teamID, 120)
        end)
        local hunterHealth = 90
        local hunterHookName = "HunterHook_" .. hunter:EntIndex()
        hook.Add("EntityTakeDamage", hunterHookName, function(ent, dmginfo)
            if ent == hunter then
                hunterHealth = hunterHealth - dmginfo:GetDamage()
                if hunterHealth <= 0 then
                    hook.Remove("EntityTakeDamage", hunterHookName)
                    local killattack = DamageInfo()
                    if not IsValid(hunter) then return end
                    killattack:SetDamage(9999)
                    killattack:SetAttacker(game.GetWorld())
                    killattack:SetInflictor(game.GetWorld())
                    killattack:SetDamageType(DMG_BLAST)
                    killattack:SetDamagePosition(hunter:GetPos())
                    killattack:SetDamageForce(Vector(0,0,0))
                    hunter:TakeDamageInfo(killattack)
                end
            end
        end)
    end)
end

local function AcidSpitterSpawn(teamID, delay, pos)
    timer.Simple(delay, function()
        local acidSpitter = ents.Create("npc_antlion")
        local teamname = getTeamNameFromID(teamID)
        acidSpitter:SetPos(pos)
        acidSpitter:SetName(teamname .. "team")
        --262916 = worker type + fall to ground + long visibility + fade corpse
        acidSpitter:AddSpawnFlags(262916)
        acidSpitter:Spawn()

        -- Antlions will kill themselves if they are spawned inside of something, like the triggers for pushing team units away from their spawns
        -- Very hacky fix for this, but it works kinda
        -- idk how this was avoided with the map templated antlions
        acidSpitter:SetNotSolid(true)
        timer.Simple(0.8, function()
            acidSpitter:SetNotSolid(false)
        end)
        timer.Simple(0.2, function()
            AttachTeamIndicator(acidSpitter, teamID, 70)
        end)
    end)
end

local function ManhackSpawn(teamID, delay, pos)
    timer.Simple(delay, function()
        local manhack = ents.Create("npc_manhack")
        local teamname = getTeamNameFromID(teamID)
        manhack:SetPos(pos)
        manhack:SetName(teamname .. "team")
        manhack:AddSpawnFlags(272132)
        manhack:Spawn()
        timer.Simple(0.2, function()
            AttachTeamIndicator(manhack, teamID, 30)
        end)
        local timeTilAutoKill = 45
        timer.Simple(timeTilAutoKill, function()
            if IsValid(manhack) then
                local killattack = DamageInfo()
                killattack:SetDamage(9999)
                killattack:SetAttacker(game.GetWorld())
                killattack:SetInflictor(game.GetWorld())
                killattack:SetDamageType(DMG_BLAST)
                killattack:SetDamagePosition(manhack:GetPos())
                killattack:SetDamageForce(Vector(0,0,0))
                manhack:TakeDamageInfo(killattack)
            end
        end)
    end)
end
mobs[1] = {
    ["headcrab"] = Mob.new("Headcrab", {"npc_headcrab"}, 1, 1),
    ["blackheadcrab"] = Mob.new("Black Headcrab", {"npc_blackheadcrab"}, 1),
    ["fastheadcrab"] = Mob.new("Fast Headcrab", {"npc_fastheadcrab"}, 1),
    ["manhack"] = Mob.new("Manhack", {"npc_manhack"}, 1, 0.5, ManhackSpawn),
    ["crowbar"] = Mob.new("Crowbar Guy", {"npc_crowbar"}, 1),
    ["stun"] = Mob.new("Stop Resisting", {"npc_stun"}, 1),
    ["torso"] = Mob.new("Zombie Torso", {"npc_torso"}, 1),
    ["rollermine"] = Mob.new("Rollermine", {"not_used"}, 1, 0.5, RollermineSpawn),
    ["fasttorso"] = Mob.new("Fast Torso", {"npc_fasttorso"}, 1)
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
    ["triplemanhack"] = Mob.new("Manhack (x3)", {"npc_manhack"}, 3, 0.3, ManhackSpawn),
    ["doublerollermine"] = Mob.new("Rollermine (x2)", {"npc_rollermine"}, 2, 0.5, RollermineSpawn),
    ["acidspitter"] = Mob.new("Acid Spitter", {"not_used"}, 1, 1, AcidSpitterSpawn)
}

mobs[3] = {
    ["rocket"] = Mob.new("Rocketeer", {"npc_rocket"}, 1),
    ["barney"] = Mob.new("Barney", {"npc_barney"}, 1),
    ["vort"] = Mob.new("Vortigaunt", {"npc_vort"}, 1),
    ["monk"] = Mob.new("Monk", {"npc_monk"}, 1),
    ["suicide"] = Mob.new("Suicide", {"npc_suicide"}, 1, 0.5),
    -- ["healer"] = Mob.new("Healer", {"npc_healer"}, 1),
    ["doublezombie"] = Mob.new("Zombie (x2)", {"npc_zombie"}, 2, 0.75),
    ["beefcake"] = Mob.new("Beefcake", {"npc_beefcake"}, 1),
    ["sniper"] = Mob.new("Combine Sniper", {"npc_sniper"}, 1, 1, CombineSniperSpawn),
    ["triplerollermine"] = Mob.new("Rollermine (x3)", {"npc_rollermine"}, 3, 0.5, RollermineSpawn),
    ["stalker"] = Mob.new("Stalker", {"npc_stalker"}, 1, 1, StalkerSpawn),
    ["grenadier"] = Mob.new("Grenadier", {"not_used"}, 1, 1, GrenadierSpawn),
    ["brute"] = Mob.new("Brute", {"npc_brute"}, 1),
    ["hunter"] = Mob.new("Hunter", {"not_used"}, 1, 1, HunterSpawn)
}

mobs[4] = {
    ["doublerocket"] = Mob.new("Rocketeer (x2)", {"npc_rocket"}, 2),
    ["quinzombie"] = Mob.new("Zombie (x5)", {"npc_zombie"}, 5, 0.5),
    ["antguard"] = Mob.new("Antlion Guard", {"npc_antguard"}, 1, 1, AntlionGuardSpawn),
    ["valkyrie"] = Mob.new("Valkyrie", {"npc_valkyrie"}, 1, 1),
    ["antlion"] = Mob.new("Antlion (x5)", {"npc_antlion"}, 5, 0.5),
    -- ["healer"] = Mob.new("Healer (x3)", {"npc_healer"}, 3), -- this guy sucks and should be replaced and also no relationship code to make him hate his own team yet
    ["bombsquad"] = Mob.new("Bombing Squad", {"npc_bombsquad"}, 3, 0.3),
    ["elitesquad"] = Mob.new("Elite Squad", {"npc_elitesquad_ar", "npc_elitesquad_shot"}, 1, 1),
    ["doublesniper"] = Mob.new("Combine Sniper (x2)", {"npc_sniper"}, 2, 1, CombineSniperSpawn),
    ["quinrollermine"] = Mob.new("Rollermine (x5)", {"npc_rollermine"}, 5, 0.4, RollermineSpawn),
    ["doublestalker"] = Mob.new("Stalker (x2)", {"npc_stalker"}, 2, 1, StalkerSpawn),
    ["doublegrenadier"] = Mob.new("Grenadier (x2)", {"not_used"}, 2, 1, GrenadierSpawn),
    ["aegisshieldunit"] = Mob.new("Aegis Shield Unit", {"not_used"}, 1, 1, AegisShieldUnitSpawn),
    ["quadacidspitter"] = Mob.new("Acid Spitter (x4)", {"not_used"}, 4, 0.8, AcidSpitterSpawn),
    ["doublehunter"] = Mob.new("Hunter (x2)", {"not_used"}, 2, 1, HunterSpawn)
}

function enableWallhacks()
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

function disableWallhacks()
    hook.Remove("PreDrawHalos", "GiveNPCsOutlines")
end
