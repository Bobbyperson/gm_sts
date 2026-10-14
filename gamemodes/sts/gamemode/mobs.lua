mobs = {}
-- Define the Mob object
Mob = {}
Mob.__index = Mob
-- Constructor for the Mob
function Mob.new(name, templates, multiplier, delay)
    -- This is the table we will return
    local EmptyMob = {
        name = name or "",
        templates = templates or {},
        multiplier = multiplier or 1, -- x3
        delay = delay or 1 -- spawning delay for groups
    }

    setmetatable(EmptyMob, Mob) -- Set the metatable of 'EmptyMob' to 'Mob'
    return EmptyMob -- Return the 'EmptyMob' table, whose metatable is 'Mob'. This is our object
end

function Mob:getSpawns(teamID, strength)
    local amount = self.multiplier * strength
    local mobsToSpawn = {}
    for _, key in ipairs(self.templates) do
        for _ = 1, amount do
            table.insert(mobsToSpawn, {function() spawnNativeMob(key, teamID) end, self.delay})
        end
    end
    return mobsToSpawn
end

-- Every mob used to be a Hammer point_template ({team}_{key}_template) in maps/gm_sts.vmf, ForceSpawn'd
-- by name. mobSpawnDefs replaces that: same keys used by the `templates` lists in mobs[1..4] below, but
-- spawnNativeMob() builds the NPC directly in Lua instead of relying on map entities.
--
-- health/maxhealth mirror the SetHealth/max_health overrides the map's landing triggers used to apply
-- (most mobs keep their class's stock health - only left nil below where the map didn't override it).
-- selfDestruct mirrors the landing triggers' delayed "SetHealth 0" self-destruct timers (manhack/vort/
-- antguard/bombsquad). quirk replicates behavior the map wired up beyond spawning a plain NPC.
-- global: init.lua also uses this to tint headcrabs/manhacks assigned to a team
teamColorStrings = {
    ["redteam"] = "255 0 0",
    ["blueteam"] = "0 0 255",
    ["greenteam"] = "0 255 0",
    ["yellowteam"] = "255 255 0"
}

-- The map's proximity triggers were brushes *parented* to the mob, so they rotated with it and
-- sat at a fixed offset from its origin - a sphere around the origin is not the same shape. The
-- offset/half-extent constants below each quirk are that brush, converted into the mob's local
-- frame (+x forward, +y left, +z up).
local function overlapsLocalBox(ent, other, offset, halfExtents)
    local lp = ent:WorldToLocal(other:WorldSpaceCenter()) - offset
    local cx = math.Clamp(lp.x, -halfExtents.x, halfExtents.x)
    local cy = math.Clamp(lp.y, -halfExtents.y, halfExtents.y)
    local cz = math.Clamp(lp.z, -halfExtents.z, halfExtents.z)
    -- treat the other entity as a sphere so this approximates brush-vs-hull touch, not point-in-box
    local r = other:BoundingRadius()
    return Vector(lp.x - cx, lp.y - cy, lp.z - cz):LengthSqr() <= r * r
end

local function boxReach(offset, halfExtents)
    return offset:Length() + halfExtents:Length() + 64 -- + slack for the widest BoundingRadius
end

-- enemy NPC or enemy player overlapping the mob's trigger box. The map's filter was
-- filter_notredteam (NOT name "redteam*"), which also passed for same-team *players* - that let a
-- red player set off their own team's suicide zombie. Kept as enemies-only instead.
local function findEnemyInBox(ent, teamName, offset, halfExtents)
    local teamKey = teamName .. "team"
    for _, victim in ipairs(ents.FindInSphere(ent:GetPos(), boxReach(offset, halfExtents))) do
        local hostile = false
        if victim:IsNPC() and victim:GetName() ~= "" then
            hostile = string.sub(victim:GetName(), 1, #teamKey) ~= teamKey
        elseif victim:IsPlayer() and victim:Alive() then
            hostile = victim:Team() ~= getTeamIDFromName(teamName)
        end

        if hostile and overlapsLocalBox(ent, victim, offset, halfExtents) then return victim end
    end
    return nil
end

-- wounded allied NPCs inside the box. Matches the map's filter_activator_name "<team>team*", so
-- prefix (not exact) - "redteamnotp" entities like the valkyrie's turrets count as allies too.
local function findAlliesInBox(ent, teamName, offset, halfExtents)
    local teamKey = teamName .. "team"
    local allies = {}
    for _, ally in ipairs(ents.FindInSphere(ent:GetPos(), boxReach(offset, halfExtents))) do
        if ally ~= ent and ally:IsNPC() and string.sub(ally:GetName(), 1, #teamKey) == teamKey
            and ally:Health() > 0 and ally:Health() < ally:GetMaxHealth()
            and overlapsLocalBox(ent, ally, offset, halfExtents) then
            allies[#allies + 1] = ally
        end
    end
    return allies
end

-- Entity:SetHealth(0) only writes the health field - it doesn't run death code, so the NPC
-- keeps walking/fighting with 0 HP. Route through TakeDamage so it actually dies.
local function killMob(ent)
    if not IsValid(ent) then return end
    ent:TakeDamage(ent:Health() + 1, ent, ent)
end

-- position and inflictor are split out from explodeMob so a lit fuse can still go off at the mob's
-- last known spot after the mob itself has been removed
local function explodeAt(pos, magnitude, radius, inflictor)
    local ed = EffectData()
    ed:SetOrigin(pos)
    util.Effect("Explosion", ed)
    local source = IsValid(inflictor) and inflictor or game.GetWorld()
    util.BlastDamage(source, source, pos, radius, magnitude)
end

local function explodeMob(ent, magnitude, radius)
    if not IsValid(ent) then return end
    explodeAt(ent:GetPos(), magnitude, radius, ent)
    killMob(ent)
end

-- Light a fuse that survives the mob dying. The map parented its env_explosion to the mob, so a mob
-- killed mid-fuse took the explosion with it - and both fused mobs are fragile things that have just
-- closed to melee, so they lost the race constantly and simply died without detonating. Tracking the
-- position each tick keeps the blast where it actually died, so the telegraph stays but the payload
-- always lands.
local function fuseExplode(ent, fuse, magnitude, radius)
    local pos = ent:GetPos()
    local timerName = "MobFuse" .. ent:EntIndex()
    local remaining = fuse
    timer.Create(timerName, 1 / 10, 0, function()
        if IsValid(ent) then pos = ent:GetPos() end
        remaining = remaining - 1 / 10
        if remaining > 0 then return end
        timer.Remove(timerName)
        if IsValid(ent) then
            explodeMob(ent, magnitude, radius)
        else
            explodeAt(pos, magnitude, radius, nil)
        end
    end)
end

-- suicide: red_npc_suicide_trig, a 72x80x68 brush 12 forward / 30 up from the zombie. Armed 1s
-- after landing (relay OnSpawn -> Enable delay 1), then a 1s fuse before the blast
-- (trigger OnStartTouch -> Explode delay 1). Blast is iMagnitude 500 / iRadiusOverride 100.
local SUICIDE_BOX_OFFSET = Vector(12, 0, 30)
local SUICIDE_BOX_HALF = Vector(40, 36, 34)

local function suicideQuirk(ent, teamName)
    timer.Simple(1, function()
        if not IsValid(ent) then return end
        local timerName = "SuicideWatch" .. ent:EntIndex()
        timer.Create(timerName, 1 / 10, 0, function()
            if not IsValid(ent) or ent:Health() <= 0 then
                timer.Remove(timerName)
                return
            end

            if findEnemyInBox(ent, teamName, SUICIDE_BOX_OFFSET, SUICIDE_BOX_HALF) then
                timer.Remove(timerName)
                -- fuse keeps burning even if the enemy walks back out, same as the map's trigger_once
                fuseExplode(ent, 1, 500, 100)
            end
        end)
    end)
end

-- bombsquad: red_npc_bombsquad_trig, a flat 56x16x56 plate 32 units *in front* of the manhack - it
-- has to be facing its victim, it is not an all-round aura. Armed immediately, 0.3s fuse
-- (OnStartTouch -> Explode delay 0.3, SetHealth 0 at 0.31). Blast is iMagnitude 80 / radius 250.
local BOMBSQUAD_BOX_OFFSET = Vector(32, 0, 0)
local BOMBSQUAD_BOX_HALF = Vector(8, 28, 28)

local function bombsquadQuirk(ent, teamName)
    local timerName = "BombsquadWatch" .. ent:EntIndex()
    timer.Create(timerName, 1 / 10, 0, function()
        if not IsValid(ent) or ent:Health() <= 0 then
            timer.Remove(timerName)
            return
        end

        if findEnemyInBox(ent, teamName, BOMBSQUAD_BOX_OFFSET, BOMBSQUAD_BOX_HALF) then
            timer.Remove(timerName)
            fuseExplode(ent, 0.3, 80, 250)
        end
    end)
end

-- brute: the map's landing trigger sprints it unconditionally 2s after arriving
local function bruteQuirk(ent)
    timer.Simple(2, function()
        if IsValid(ent) then ent:Fire("StartSprint") end
    end)
end

-- healer: an npc_cscanner whose heal was red_npc_healer_trig - a trigger_hurt with damage -2
-- (negative damage heals) parented to it, filter_redteam_only. The brush is a long narrow
-- 32x209x85 volume running *forward* from the scanner, so it is a directional heal ray, not an
-- aura, and it hit every ally touching it rather than a single target. trigger_hurt applies its
-- damage every 0.5s, so the map rate is 2 HP per 0.5s = 4 HP/s.
-- "HealerTarget" is read client-side to draw the beam.
local HEALER_BOX_OFFSET = Vector(119, 0, -46)
local HEALER_BOX_HALF = Vector(105, 16, 42)
local HEALER_TICK = 0.5
local HEALER_HEAL = 2
local HEALER_SOUND = "WallHealth.LoopingContinueCharge" -- map: ambient_generic red_npc_healer_sound

local function healerQuirk(ent, teamName)
    local teamKey = teamName .. "team"
    local timerName = "HealerWatch" .. ent:EntIndex()
    -- AssignTeam() gives every teammate a D_LI priority-10 relationship toward each other, and every
    -- enemy a D_HT priority-10. Overriding just the current focus to D_HT at a higher priority makes
    -- the cscanner's own FindEnemy/combat AI fly at and engage it - movement and facing come entirely
    -- from that native AI, not from us calling SetPos/SetAngles/SetSchedule. That is also what swings
    -- the heal box onto the ally. Restored back to D_LI once it is no longer the focus.
    --
    -- Enemies get pushed to D_NU at priority 15 (above AssignTeam's 10, below the focus's 20) so the
    -- lowest-health teammate is the ONLY thing a healer ever hates. Without this the healer breaks
    -- off to chase whatever enemy came closest and stops healing. One-directional - enemies still
    -- hate the healer back, so it stays killable.
    ent.stsHealer = true -- healers must not heal or focus each other; see the stsHealer checks below
    local hatedTarget
    local sounding = false
    local neutralised = setmetatable({}, {__mode = "k"}) -- weak so dead NPCs are not pinned in memory

    timer.Create(timerName, HEALER_TICK, 0, function()
        if not IsValid(ent) or ent:Health() <= 0 then
            if IsValid(ent) then
                if IsValid(hatedTarget) then ent:AddEntityRelationship(hatedTarget, D_LI, 20) end
                if sounding then ent:StopSound(HEALER_SOUND) end
            end

            timer.Remove(timerName)
            return
        end

        -- AssignTeam re-hates the healer every time a new NPC spawns, so keep neutralising newcomers.
        -- Only unseen pairs are touched, so this is one AddEntityRelationship per enemy, not per tick.
        for _, other in ipairs(ents.GetAll()) do
            if other ~= ent and other:IsNPC() and not neutralised[other] then
                local name = other:GetName()
                if name ~= "" and string.sub(name, 1, #teamKey) ~= teamKey then
                    ent:AddEntityRelationship(other, D_NU, 15)
                    neutralised[other] = true
                end
            end
        end

        -- everything the beam volume covers gets healed, not just the focus - but never another healer
        local healed = 0
        for _, ally in ipairs(findAlliesInBox(ent, teamName, HEALER_BOX_OFFSET, HEALER_BOX_HALF)) do
            if not ally.stsHealer then
                ally:SetHealth(math.min(ally:GetMaxHealth(), ally:Health() + HEALER_HEAL))
                healed = healed + 1
            end
        end

        if healed > 0 and not sounding then
            ent:EmitSound(HEALER_SOUND)
            sounding = true
        elseif healed == 0 and sounding then
            ent:StopSound(HEALER_SOUND)
            sounding = false
        end

        -- focus is picked from a wider radius than the heal box so the scanner will actually fly
        -- over to a wounded ally instead of only healing whatever wandered in front of it
        local target, lowestHealth
        for _, ally in ipairs(ents.FindInSphere(ent:GetPos(), 350)) do
            if ally ~= ent and ally:IsNPC() and not ally.stsHealer and string.sub(ally:GetName(), 1, #teamKey) == teamKey and ally:Health() > 0 and ally:Health() < ally:GetMaxHealth() and (not lowestHealth or ally:Health() < lowestHealth) then
                target, lowestHealth = ally, ally:Health()
            end
        end

        if target ~= hatedTarget then
            if IsValid(hatedTarget) then ent:AddEntityRelationship(hatedTarget, D_LI, 20) end
            hatedTarget = target
        end

        -- re-assert every tick: AssignTeam() resets every same-team pair to D_LI whenever a teammate
        -- spawns, and AddEntityRelationship overwrites regardless of priority, which silently dropped
        -- the focus until the target happened to change
        if target then ent:AddEntityRelationship(target, D_HT, 20) end

        ent:SetNWEntity("HealerTarget", target)
    end)
end

-- map's env_beam was team-coloured (rendercolor matched the team) on sprites/laserbeam.spr
local healerBeamColors = {
    ["redteam"] = Color(255, 0, 0),
    ["blueteam"] = Color(51, 51, 255),
    ["greenteam"] = Color(0, 255, 0),
    ["yellowteam"] = Color(255, 255, 0)
}

-- AssignTeam() networks the team as "redteam"/"redteamnotp"/... so match on the prefix
local function healerBeamColor(ent)
    local col = ent:GetNWString("wallhack_col", ""):lower()
    for key, colour in pairs(healerBeamColors) do
        if string.sub(col, 1, #key) == key then return colour end
    end

    return Color(255, 255, 255)
end

-- client-side visual for healerQuirk: never fires on the server since PostDrawTranslucentRenderables
-- only runs client-side (same reasoning as the halo hooks below not needing an explicit CLIENT guard).
local healerBeamMaterial = CLIENT and Material("sprites/laserbeam.spr")
hook.Add("PostDrawTranslucentRenderables", "DrawHealerBeams", function()
    for _, ent in ipairs(ents.FindByClass("npc_cscanner")) do
        local target = ent:GetNWEntity("HealerTarget")
        if IsValid(target) then
            render.SetMaterial(healerBeamMaterial)
            render.DrawBeam(ent:GetPos(), target:GetPos(), 6, 0, 1, healerBeamColor(ent))
        end
    end
end)

-- valkyrie: really a re-equipped npc_cscanner escorted by two mounted floor turrets. Offsets come
-- from the map's red_npc_valkyrieturret pair relative to red_npc_valkyrie: 22 back, 25 out to each
-- side, 19.71 down, pitched 30 up. Has to be LocalToWorld - the old Vector(-15, 0, -25) was added
-- in *world* space, so it did not rotate with the scanner and shoved both turrets the same way,
-- landing them at -35 and +5 instead of a symmetric +/-25.
local function valkyrieQuirk(ent, teamName)
    for _, side in ipairs({1, -1}) do
        local turret = ents.Create("npc_turret_floor")
        if IsValid(turret) then
            turret:SetPos(ent:LocalToWorld(Vector(-22, side * 25, -19.71)))
            turret:SetAngles(ent:GetAngles() + Angle(30, 0, 0))
            turret:SetKeyValue("modelscale", ".5")
            turret:SetKeyValue("rendercolor", teamColorStrings[teamName .. "team"] or "255 255 255")
            turret:Spawn()
            turret:Activate()
            turret:SetParent(ent)
            turret:SetName(teamName .. "teamnotp")
            local phys = turret:GetPhysicsObject()
            if IsValid(phys) then phys:SetMass(0.01) end
        end
    end
end

mobSpawnDefs = {
    ["npc_headcrab"] = {classname = "npc_headcrab", kv = {spawnflags = "9732", startburrowed = "No", wakeradius = "1"}, health = 25},
    ["npc_blackheadcrab"] = {classname = "npc_headcrab_black", kv = {spawnflags = "9732", startburrowed = "No", wakeradius = "1"}, health = 25},
    ["npc_fastheadcrab"] = {classname = "npc_headcrab_fast", kv = {spawnflags = "9732", startburrowed = "No", wakeradius = "1"}, health = 25},
    ["npc_manhack"] = {classname = "npc_manhack", kv = {spawnflags = "272132", wakeradius = "1"}, selfDestruct = 30},
    ["npc_crowbar"] = {classname = "npc_citizen", kv = {additionalequipment = "weapon_crowbar", citizentype = "3", ammosupply = "SMG1", ammoamount = "1", expressiontype = "3", model = "models/humans/group01/male_01.mdl", spawnflags = "9732", wakeradius = "1"}},
    ["npc_stun"] = {classname = "npc_metropolice", kv = {additionalequipment = "weapon_stunstick", manhacks = "0", spawnflags = "9732", wakeradius = "1"}, health = 25},
    ["npc_torso"] = {classname = "npc_zombie_torso", kv = {spawnflags = "9732", wakeradius = "1"}, health = 50},
    ["npc_fasttorso"] = {classname = "npc_fastzombie_torso", kv = {spawnflags = "9732", wakeradius = "1"}, health = 40},
    ["npc_medic"] = {classname = "npc_citizen", kv = {additionalequipment = "weapon_crowbar", citizentype = "3", ammosupply = "SMG1_Grenade", ammoamount = "1", DontPickupWeapons = "1", expressiontype = "2", model = "models/humans/group01/female_04.mdl", spawnflags = "665092", wakeradius = "2"}, health = 25},
    ["npc_shotgun"] = {classname = "npc_combine_s", kv = {additionalequipment = "weapon_shotgun", model = "models/combine_soldier_prisonguard.mdl", tacticalvariant = "1", NumGrenades = "999999", spawnflags = "9732", wakeradius = "2"}, health = 40},
    ["npc_combinesmg"] = {classname = "npc_combine_s", kv = {additionalequipment = "weapon_smg1", model = "models/combine_soldier.mdl", tacticalvariant = "2", NumGrenades = "999999", spawnflags = "9732", wakeradius = "2"}},
    ["npc_cop"] = {classname = "npc_metropolice", kv = {additionalequipment = "weapon_pistol", manhacks = "1", spawnflags = "9988", wakeradius = "2"}},
    ["npc_zombie"] = {classname = "npc_fastzombie", kv = {spawnflags = "9988", wakeradius = "2"}},
    ["npc_antlion"] = {classname = "npc_antlion", kv = {eludedist = "1024", radius = "1024", spawnflags = "9988", startburrowed = "No", wakeradius = "2"}, health = 50},
    ["npc_rocket"] = {classname = "npc_citizen", kv = {additionalequipment = "weapon_rpg", ammosupply = "RPG_Round", ammoamount = "1", citizentype = "3", DontPickupWeapons = "1", expressiontype = "3", model = "models/humans/group01/male_07.mdl", spawnflags = "9988", wakeradius = "5"}, health = 40},
    ["npc_barney"] = {classname = "npc_citizen", kv = {additionalequipment = "weapon_ar2", ammosupply = "SMG1", ammoamount = "1", citizentype = "4", model = "models/barney.mdl", expressiontype = "Random", spawnflags = "9988", wakeradius = "5"}, health = 65},
    ["npc_vort"] = {classname = "npc_vortigaunt", kv = {DontPickupWeapons = "1", ArmorRechargeEnabled = "1", HealthRegenerateEnabled = "0", model = "models/vortigaunt.mdl", spawnflags = "9732", wakeradius = "2"}, health = 50, selfDestruct = 50},
    ["npc_monk"] = {classname = "npc_citizen", kv = {additionalequipment = "weapon_annabelle", ammosupply = "SMG1", ammoamount = "1", citizentype = "4", model = "models/monk.mdl", expressiontype = "Random", spawnflags = "9988", wakeradius = "5"}, health = 30},
    ["npc_suicide"] = {classname = "npc_fastzombie", kv = {spawnflags = "9988", wakeradius = "1"}, health = 80, tint = true, quirk = suicideQuirk},
    ["npc_beefcake"] = {classname = "npc_poisonzombie", kv = {crabcount = "3", spawnflags = "9988", wakeradius = "5"}, health = 120},
    ["npc_brute"] = {classname = "npc_zombine", kv = {spawnflags = "9988", wakeradius = "5"}, health = 120, quirk = bruteQuirk},
    ["npc_antguard"] = {classname = "npc_antlionguard", kv = {allowbark = "No", spawnflags = "9988", wakeradius = "25"}, health = 150, selfDestruct = 25},
    ["npc_valkyrie"] = {classname = "npc_cscanner", kv = {spotlightlength = "500", spotlightwidth = "50", ShouldInspect = "1", spawnflags = "9988", wakeradius = "5"}, health = 35, quirk = valkyrieQuirk},
    ["npc_healer"] = {classname = "npc_cscanner", kv = {modelscale = ".5", spotlightlength = "500", spotlightwidth = "50", ShouldInspect = "1", spawnflags = "516", wakeradius = "0"}, selfDestruct = 45, quirk = healerQuirk},
    ["npc_bombsquad"] = {classname = "npc_manhack", kv = {modelscale = ".5", spawnflags = "272132", wakeradius = "1"}, health = 50, selfDestruct = 30, tint = true, quirk = bombsquadQuirk},
    ["npc_elitesquad_ar"] = {classname = "npc_combine_s", kv = {additionalequipment = "weapon_ar2", model = "models/combine_super_soldier.mdl", tacticalvariant = "0", NumGrenades = "999999", spawnflags = "9988", wakeradius = "3"}, health = 70},
    ["npc_elitesquad_shot"] = {classname = "npc_combine_s", kv = {additionalequipment = "weapon_shotgun", model = "models/combine_super_soldier.mdl", tacticalvariant = "1", NumGrenades = "999999", spawnflags = "9988", wakeradius = "3"}, health = 70}
}

-- Where a mob is built before beginTeamAssignment()'s OnEntityCreated hook teleports it to a random
-- arena spawn ~8 ticks (0.12s) later. One spot per team is enough because that teleport clears it.
--
-- These MUST stay clear of the map's {team}_npc_tp_trig brushes. Each of those is a per-mob-cell
-- landing trigger that fires, on ANY touch: AddOutput(targetname <team>team), AddOutput(max_health N)
-- and SetHealth(N) at +0.25s - where N is that *cell's* mob health. The earlier coordinates sat
-- dead centre inside the headcrab cell's trigger, so every mob spawned here inherited the headcrab's
-- 25 HP a quarter-second after spawn, silently overriding def.health for the whole roster.
-- (The trigger's three other outputs point at entities that no longer exist in the map.)
--
-- Picked by sweeping each team's room for a floor cell whose standing hull clears every world brush
-- and every brush entity; each has ~95u of horizontal clearance to the nearest trigger.
local mobStagingSpawn = {
    ["red"] = {pos = Vector(-15740, -11528, -9208), ang = Angle(0, 270, 0)},
    ["blue"] = {pos = Vector(-14972, -11012, -9208), ang = Angle(0, 270, 0)},
    ["green"] = {pos = Vector(-14300, -10516, -9208), ang = Angle(0, 270, 0)},
    ["yellow"] = {pos = Vector(-13604, -9920, -9208), ang = Angle(0, 270, 0)}
}

function spawnNativeMob(key, teamID)
    local def = mobSpawnDefs[key]
    if not def then return end
    local teamName = getTeamNameFromID(teamID)
    local staging = mobStagingSpawn[teamName]
    if not staging then return end

    local ent = ents.Create(def.classname)
    if not IsValid(ent) then return end

    for k, v in pairs(def.kv or {}) do
        ent:SetKeyValue(k, v)
    end

    local teamKey = teamName .. "team"
    ent:SetKeyValue("squadname", teamKey)
    if def.tint then ent:SetKeyValue("rendercolor", teamColorStrings[teamKey] or "255 255 255") end
    ent:SetPos(staging.pos)
    ent:SetAngles(staging.ang)
    ent:SetName(teamKey) -- picked up by beginTeamAssignment()'s OnEntityCreated hook for relationships + arena teleport
    ent:Spawn()
    ent:Activate()

    if def.health then
        timer.Simple(0, function()
            if not IsValid(ent) then return end
            ent:SetMaxHealth(def.maxhealth or def.health)
            ent:SetHealth(def.health)
        end)
    end

    if def.selfDestruct then
        timer.Simple(def.selfDestruct, function() killMob(ent) end)
    end

    if def.quirk then def.quirk(ent, teamName) end

    return ent
end
mobs[1] = {
    ["headcrab"] = Mob.new("Headcrab", {"npc_headcrab"}, 1, 1),
    ["blackheadcrab"] = Mob.new("Black Headcrab", {"npc_blackheadcrab"}, 1),
    ["fastheadcrab"] = Mob.new("Fast Headcrab", {"npc_fastheadcrab"}, 1),
    ["manhack"] = Mob.new("Manhack", {"npc_manhack"}, 1, 0.5),
    ["crowbar"] = Mob.new("Crowbar Guy", {"npc_crowbar"}, 1),
    ["stun"] = Mob.new("Stop Resisting", {"npc_stun"}, 1),
    ["torso"] = Mob.new("Zombie Torso", {"npc_torso"}, 1),
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
    ["triplemanhack"] = Mob.new("Manhack (x3)", {"npc_manhack"}, 3, 0.3)
}

mobs[3] = {
    ["rocket"] = Mob.new("Rocketeer", {"npc_rocket"}, 1),
    ["barney"] = Mob.new("Barney", {"npc_barney"}, 1),
    ["vort"] = Mob.new("Vortigaunt", {"npc_vort"}, 1),
    ["monk"] = Mob.new("Monk", {"npc_monk"}, 1),
    ["suicide"] = Mob.new("Suicide", {"npc_suicide"}, 1, 0.5),
    ["healer"] = Mob.new("Healer", {"npc_healer"}, 1),
    ["doublezombie"] = Mob.new("Zombie (x2)", {"npc_zombie"}, 2, 0.75),
    ["beefcake"] = Mob.new("Beefcake", {"npc_beefcake"}, 1),
    ["brute"] = Mob.new("Brute", {"npc_brute"}, 1)
}

mobs[4] = {
    ["doublerocket"] = Mob.new("Rocketeer (x2)", {"npc_rocket"}, 2),
    ["quinzombie"] = Mob.new("Zombie (x5)", {"npc_zombie"}, 5, 0.5),
    ["antguard"] = Mob.new("Antlion Guard", {"npc_antguard"}, 1),
    ["valkyrie"] = Mob.new("Valkyrie", {"npc_valkyrie"}, 1, 1),
    ["antlion"] = Mob.new("Antlion (x5)", {"npc_antlion"}, 5, 0.5),
    ["healer"] = Mob.new("Healer (x3)", {"npc_healer"}, 3),
    ["bombsquad"] = Mob.new("Bombing Squad", {"npc_bombsquad"}, 3, 0.3),
    ["elitesquad"] = Mob.new("Elite Squad", {"npc_elitesquad_ar", "npc_elitesquad_shot"}, 1, 1)
}

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