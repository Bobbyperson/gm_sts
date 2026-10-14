include("mobs.lua")
Cube = {}
Cube.__index = Cube
function Cube.new(entity, level, rarity, strength, multiplier, mob, key)
    local EmptyCube = {
        entity = entity or "",
        level = level or 1,
        rarity = rarity or 1,
        strength = strength or 1,
        multiplier = multiplier or 1,
        mob = mob,
        key = key or ""
    }

    setmetatable(EmptyCube, Cube)
    return EmptyCube
end

function Cube:setMob(raritychoice, mobchoice, strength)
    self.mob = mobs[raritychoice][mobchoice]
    self.key = mobchoice
    self.strength = strength
end

function Cube:randomize()
    local chosenMob
    if self.level == 1 then
        self.rarity = 1
    elseif self.level == 2 then
        self.rarity = math.random(1, 2)
    elseif self.level == 3 then
        self.rarity = math.random(2, 3)
    elseif self.level == 4 then
        self.rarity = math.random(3, 4)
    elseif self.level == 5 then
        self.rarity = 4
    else
        PrintMessage(HUD_PRINTTALK, "Malformed cube at " .. self.entity .. "\nPlease screenshot and report in the discord!")
        return false
    end

    -- iterate over whole table to get all keys
    local keyset = {}
    for k in pairs(mobs[self.rarity]) do
        table.insert(keyset, k)
    end

    chosenMob = keyset[math.random(#keyset)]
    -- PrintMessage(HUD_PRINTTALK, chosenMob)
    self.mob = mobs[self.rarity][chosenMob]
    self.key = chosenMob
    -- PrintTable(self.mob)
    self.strength = math.random(1, 4)
    return true
end

function Cube:upgrade()
    if self.level ~= 5 then
        self.level = self.level + 1
        self:randomize()
        self:changeColor()
        return true
    end
    return false
end

function Cube:canUpgrade(points)
    local cost = self.level * 6
    if points >= cost then
        return true
    else
        return false
    end
end

function Cube:changeColor()
    local ent = self:getEntity()
    if self.level == 1 then
        ent:SetColor(Color(138, 21, 255, 255))
    elseif self.level == 2 then
        ent:SetColor(Color(0, 0, 255, 255))
    elseif self.level == 3 then
        ent:SetColor(Color(0, 255, 0, 255))
    elseif self.level == 4 then
        ent:SetColor(Color(4, 186, 255, 255))
    elseif self.level == 5 then
        ent:SetColor(Color(185, 185, 255, 255))
    else
        ent:SetColor(0, 0, 0, 255)
    end
end

function Cube:getEntity()
    for i, ent in ipairs(ents.GetAll()) do
        if ent:GetName() == self.entity then return ent end
    end
end
