local entMeta = FindMetaTable( "Entity" )

entMeta.o_SetNotSolid = entMeta.o_SetNotSolid or entMeta.SetNotSolid
function entMeta:SetNotSolid( solid )
    if self:GetClass() == "gmod_sent_vehicle_fphysics_base" then
        self:o_SetNotSolid( solid )
        return
    end

    if self:GetClass() == "prop_vehicle_prisoner_pod" and self:GetOwner():GetClass() == "gmod_sent_vehicle_fphysics_base" then
        self:o_SetNotSolid( solid )
        return
    end

    if self:IsVehicle() and not solid then return end
    return self:o_SetNotSolid( solid )
end

entMeta.o_SetSolid = entMeta.o_SetSolid or entMeta.SetSolid
function entMeta:SetSolid( solid )
    if self:IsVehicle() and solid == SOLID_NONE then return end
    return self:o_SetSolid( solid )
end

entMeta.o_SetSolidFlags = entMeta.o_SetSolidFlags or entMeta.SetSolidFlags
function entMeta:SetSolidFlags( flags )
    local solid = bit.band( flags, FSOLID_NOT_SOLID )
    if self:IsVehicle() and solid ~= 0 then return end
    return self:o_SetSolidFlags( flags )
end
