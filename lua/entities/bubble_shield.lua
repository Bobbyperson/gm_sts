AddCSLuaFile()
ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.PrintName = "Bubble Shield"
ENT.Spawnable = true 



function ENT:Initialize()
    self:SetModel("models/props_phx/construct/metal_dome360.mdl")
    self:SetMaterial("models/props_combine/portalball001_sheet")
    self:SetColor(Color(0, 100, 255, 100))
    self:SetRenderMode(RENDERMODE_TRANSALPHA)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_NONE)
    self:SetModelScale(2.3, 0.001)
    self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE) -- So NPCs can walk through
end

function ENT:SetTeamName(name)
    self:SetNWString("TeamName", name)
end

function ENT:GetTeamName()
    return self:GetNWString("TeamName")
end