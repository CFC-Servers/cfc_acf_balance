local entMeta = FindMetaTable( "Entity" )

entMeta.o_SetNotSolid = entMeta.o_SetNotSolid or entMeta.SetNotSolid
function entMeta:SetNotSolid( solid )
    if solid and self:IsVehicle() then
        return
    end

    self:o_SetNotSolid( solid )
end
