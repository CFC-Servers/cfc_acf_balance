local istable = istable
local entMeta = FindMetaTable( "Entity" )

entMeta.o_SetNotSolid = entMeta.o_SetNotSolid or entMeta.SetNotSolid
function entMeta:SetNotSolid( solid )
    if not self:IsVehicle() or solid then
        return self:o_SetNotSolid( solid )
    end

    -- Only affect wire pod linked seats
    local entTable = self:GetTable()
    if not istable( entTable.OnDieFunctions ) then
        return self:o_SetNotSolid( solid )
    end

    if not entTable.OnDieFunctions.wire_pod_remove then
        return self:o_SetNotSolid( solid )
    end
end
